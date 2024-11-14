local love = love
local lg = love.graphics

local function drawPremul(canvas, ...)
  lg.setBlendMode("alpha", "premultiplied")
  lg.draw(canvas, ...)
  lg.setBlendMode("alpha", "alphamultiply")
end

local bump = require "lib.bump"
local flux = require "lib.flux"

local bouncer = require "entities.bouncer"

local frameCount = 0

local quadDitherShader = lg.newShader [[
  uniform number idx;

  vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
    float ox = floor(mod(idx / 2 + 0.5, 2));
    float oy = floor(mod(idx / 2 + 0.11, 2));
    float fac = (mod(sc.x + ox, 2) + mod(sc.y + oy, 2));
    vec4 pixel = Texel(texture, tc) * color;
    return pixel * vec4(1, 1, 1, fac * 0.9);
  }
]]
local quadDitherIndex = 0

local noiseShader = lg.newShader(love.filesystem.read("shaders/snoise.glsl") ..
  love.filesystem.read("shaders/noiseBackground.glsl"))

local tileSize = 48

local moveDirs = {
  left = { x = -1 },
  right = { x = 1 },
  up = { y = -1 },
  down = { y = 1 },

  a = { x = -1 },
  d = { x = 1 },
  w = { y = -1 },
  s = { y = 1 },
}

local maxCrosses = 100

local function playerMoveFilter(_, other)
  if other.cross then
    return "cross"
  else
    return "slide"
  end
end

local goalDuration = 3

local titleFont = lg.newFont(InterFont, 24)
local titleScale = 3

local timerFont = lg.newFont(InterFont, 150)

-- player's color will start changing when its speed is greater than (breakSpeed - this)
local breakFadeStart = 50

local function centerPos(o, x, y)
  return
      x * tileSize + tileSize / 2 - o.w / 2,
      y * tileSize + tileSize / 2 - o.h / 2
end

local function lerp(a, b, t)
  return a + (b - a) * t
end

local function lerpColor(r1, g1, b1, a1, r2, g2, b2, a2, t)
  return
      lerp(r1, r2, t),
      lerp(g1, g2, t),
      lerp(b1, b2, t),
      lerp(a1, a2, t)
end

local function objectMidX(self)
  return self.x + self.w / 2
end

local function objectMidY(self)
  return self.y + self.h / 2
end

local game = {}

function game:enter(_, level)
  self.tweens = flux.group()

  self.gameCanvas = lg.newCanvas()
  self.sideCanvas = lg.newCanvas()
  self.subCanvas = lg.newCanvas()
  self.failCanvas = lg.newCanvas()

  self.invertShader = lg.newShader [[
    vec4 lerp(vec4 a, vec4 b, float t) {
      return a + (b - a) * t;
    }

    uniform Image invertTexture;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
      vec4 pixel = Texel(texture, tc);
      vec3 multiplied = vec3(pixel) * pixel.a;
      vec4 inverted = vec4(1 - multiplied, 1);
      return lerp(pixel, inverted, Texel(invertTexture, tc).r) * color;
    }
  ]]
  self.invertShader:send("invertTexture", self.subCanvas)
  self.shockwaveShader = lg.newShader("shaders/shockwave.glsl")
  self.restartDistortShader = lg.newShader("shaders/restartDistort.glsl")
  self.restartEffect = {
    y = 0,
    size = 0.22,
    distortion = 0.1,
    direction = 1,
    enabled = false
  }

  self.trailCanvas1 = lg.newCanvas()
  self.trailCanvas2 = lg.newCanvas()

  self.scrollText = level.title
  self.textScrollX = 0
  self.textY = love.math.random(0, lg.getHeight() - titleFont:getHeight() * titleScale)

  self.shockwaves = {}
  self.shakeAmount = 0

  self:startLevel(level)
end

function game:startLevel(level)
  if level ~= self.level then
    self.deathCrosses = {}
  end

  self.level = level

  self.world = bump.newWorld(tileSize * 2)

  self.objects = {}

  for x = 0, level.width - 1 do
    for y = 0, level.height - 1 do
      local i = y * level.width + x + 1
      local tile = level.tiles[i]
      if tile == 1 then
        self:addObject({
          x = x * tileSize,
          y = y * tileSize,
          w = tileSize,
          h = tileSize,
          hurt = true,
          color = { 1, 0, 0 }
        })
      end
    end
  end

  for _, e in ipairs(level.entities) do
    if e.type == "goal" then
      local goal = {
        goal = true,
        cross = true,
        w = tileSize * .7,
        h = tileSize * .7,
        color = { 0, 1, 0 }
      }
      goal.x, goal.y = centerPos(goal, e.x, e.y)
      self:addObject(goal)
    elseif e.type == "key" then
      local key = {
        key = true,
        cross = true,
        w = tileSize * .3,
        h = tileSize * .3,
        color = { 1, 1, 0 }
      }
      key.x, key.y = centerPos(key, e.x, e.y)
      self:addObject(key)
    elseif e.type == "bouncer" then
      local b = bouncer:new(self)
      b.x, b.y = centerPos(b, e.x, e.y)
      self:addObject(b)
    else
      error("what entity type '" .. e.type .. "'????")
    end
  end

  self.player = {
    w = tileSize * .35,
    h = tileSize * .35,
    vx = 0,
    vy = 0,
    speed = 0,
    accel = 60,
    breakSpeed = 180,
    color = { 1, 1, 1 },
    moveFilter = playerMoveFilter,
    onCollision = function(_, col)
      if col.other.hurt then
        self:die()
      end

      if col.other.goal and self.keysCount >= self.level.neededKeys then
        self.touchingGoal = true
      elseif col.other.key then
        self:removeObject(col.other)
        self.keysCount = self.keysCount + 1
        self:spawnShockwave(col.other:midX(), col.other:midY(), 0, 0.05, 0.05, 0.5)
      end
    end
  }
  self.player.x, self.player.y = centerPos(self.player, level.playerX, level.playerY)

  self.dead = false
  self.won = false
  self.restartTimer = nil
  self.keysCount = 0

  self.startTime = love.timer.getTime()
  self.firstMoved = false

  self:addObject(self.player)
end

function game:addObject(obj)
  obj.midX = objectMidX
  obj.midY = objectMidY
  table.insert(self.objects, obj)
  self.world:add(obj, obj.x, obj.y, obj.w, obj.h)
end

function game:removeObject(obj)
  for i, o in ipairs(self.objects) do
    if o == obj then
      table.remove(self.objects, i)
      self.world:remove(o)
      return
    end
  end
end

function game:die()
  if self.dead then
    return
  end

  self.dead = true
  self.restartTimer = 0.8
  self:removeObject(self.player)

  local cross = {
    x = self.player:midX(),
    y = self.player:midY(),
    lw = self.player.w,
    s = self.player.w / 2,
    r = 0,
    a = 1,
  }
  self.tweens:to(cross, 0.5, { r = 0.5, lw = cross.lw / 2, s = tileSize / 2, a = 0.1 })
  table.insert(self.deathCrosses, cross)

  self:spawnShockwave(self.player:midX(), self.player:midY(), 0.02, 0.1, 0.07, 1)
  self:shake(10, 0.5)

  if #self.deathCrosses > maxCrosses then
    self.tweens:to(self.deathCrosses[1], 2, { a = 0 })
        :oncomplete(function()
          table.remove(self.deathCrosses, 1)
        end)
  end
end

function game:win()
  self.won = true
  self.winEffect = 0
  self.tweens:to(self, 2, { winEffect = 0.1 })
end

function game:shake(amount, time)
  self.shakeAmount = amount
  self.tweens:to(self, time, { shakeAmount = 0 })
end

function game:spawnShockwave(x, y, startRadius, endRadius, width, lifetime)
  local shockwave = {
    x = x,
    y = y,
    startRadius = startRadius,
    endRadius = endRadius,
    width = width,
    lifetime = lifetime,
    life = 0
  }
  self.tweens:to(shockwave, lifetime, { life = lifetime })
  table.insert(self.shockwaves, shockwave)
end

function game:gotoNextLevel()
  self:startLevel(require("levels." .. self.level.nextLevel))
end

function game:update(dt)
  if not self.dead and not self.won then
    if DebugMode and love.mouse.isDown(2) then
      self.player.x, self.player.y = love.mouse.getX() - self.cameraX, love.mouse.getY() - self.cameraY
      self.world:update(self.player, self.player.x, self.player.y)
    end

    for key, dir in pairs(moveDirs) do
      if love.keyboard.isDown(key) then
        self.player.vx = self.player.vx + self.player.accel * (dir.x or 0) * dt
        self.player.vy = self.player.vy + self.player.accel * (dir.y or 0) * dt
        self.firstMoved = true
      end
    end

    self.touchingGoal = false

    for _, obj in ipairs(self.objects) do
      if obj.update then
        obj:update(dt)
      end
      if obj.vx then
        local cols
        obj.x, obj.y, cols = self.world:move(obj, obj.x + obj.vx * dt, obj.y + obj.vy * dt, obj.moveFilter)
        obj.handledCols = {}
        if obj.onCollision then
          for _, col in ipairs(cols) do
            if not col.other.handledCols or not col.other.handledCols[obj] then
              obj:onCollision(col)
              if col.other.onCollision then
                col.other:onCollision({
                  other = obj,
                  normal = { x = -col.normal.x, y = -col.normal.y }
                })
              end
              obj.handledCols[col.other] = true
            end
          end
        end
      end
    end

    if self.touchingGoal then
      self.goalTimer = self.goalTimer + dt
      if self.goalTimer >= goalDuration then
        self:win()
      end
    else
      self.goalTimer = 0
    end

    if not self.firstMoved then
      self.startTime = love.timer.getTime()
    end
    self.levelTime = love.timer.getTime() - self.startTime

    self.player.speed = math.sqrt(self.player.vx ^ 2 + self.player.vy ^ 2)
    local factor = (self.player.speed - self.player.breakSpeed + breakFadeStart) / breakFadeStart
    self.player.color[3] = lerp(1, 0, factor)
  end

  if self.restartTimer then
    self.restartTimer = self.restartTimer - dt
    if self.restartTimer <= 0 then
      self.restartTimer = nil
      self.restartEffect.enabled = true
      self.restartEffect.y = -self.restartEffect.size
      self.restartEffect.direction = 1
      self.tweens:to(self.restartEffect, 0.7, { y = 1 + self.restartEffect.size }):ease("linear")
          :oncomplete(function()
            self.restartEffect.direction = -1
            lg.setCanvas(self.failCanvas)
            lg.clear()
            lg.setColor(1, 1, 1)
            drawPremul(self.gameCanvas)
            lg.setCanvas()
            self:startLevel(self.level)
            self.tweens:to(self.restartEffect, 0.7, { y = -self.restartEffect.size }):ease("linear")
                :oncomplete(function()
                  self.restartEffect.enabled = false
                end)
          end)
    end
  end

  self.textScrollX = self.textScrollX - dt * 200
  if self.textScrollX < -titleFont:getWidth(self.level.title) * titleScale then
    self.textScrollX = lg.getWidth()
    self.textY = love.math.random(0, lg.getHeight() - titleFont:getHeight() * titleScale)
  end

  local levelWidth = self.level.width * tileSize
  local levelHeight = self.level.height * tileSize

  local cameraX, cameraY

  if levelWidth > lg.getWidth() then
    cameraX = self.player:midX()
  else
    cameraX = levelWidth / 2
  end

  if levelHeight > lg.getHeight() then
    cameraY = self.player:midY()
  else
    cameraY = levelHeight / 2
  end

  self.cameraX = lg.getWidth() / 2 - cameraX
  self.cameraY = lg.getHeight() / 2 - cameraY

  self.tweens:update(dt)

  for i = #self.shockwaves, 1, -1 do
    if self.shockwaves[i].life >= self.shockwaves[i].lifetime then
      table.remove(self.shockwaves, i)
    end
  end
end

function game:keypressed(k)
  if k == "space" and self.won then
    self:gotoNextLevel()
  end

  if DebugMode then
    if k == "f2" then
      self:gotoNextLevel()
    end
  end
end

function game:screenPass(shader)
  lg.setCanvas(self.sideCanvas)
  lg.clear(0, 0, 0, 0)
  lg.setShader(shader)
  lg.setColor(1, 1, 1)
  drawPremul(self.gameCanvas)
  lg.setShader()
  lg.setCanvas()
  self.gameCanvas, self.sideCanvas = self.sideCanvas, self.gameCanvas
end

function game:drawNoiseBackground()
  lg.setColor(1, 1, 1, 0.5)
  lg.setShader(noiseShader)
  noiseShader:send("offset", {
    love.timer.getTime() / 20 - self.cameraX / 500,
    love.timer.getTime() / 20 - self.cameraY / 500,
    love.timer.getTime() / 10
  })
  lg.rectangle("fill", 0, 0, lg.getDimensions())
  lg.setShader()
end

function game:restartCrop()
  if self.restartEffect.enabled and self.restartEffect.direction == -1 then
    local h = self.restartEffect.y * lg.getHeight()
    lg.setScissor(0, h, lg.getWidth(), math.max(lg.getHeight() - h, 0))
  end
end

function game:drawTimer()
  lg.print(("%.2f"):format(self.levelTime),
    lg.getWidth() / 2 - timerFont:getWidth(("4"):rep(math.max(math.log(math.floor(self.levelTime), 10), 1) + 2)) / 2,
    lg.getHeight() / 2 - timerFont:getHeight() / 2)
end

function game:draw()
  if self.restartEffect.enabled then
    self.restartDistortShader:send("yPosition", self.restartEffect.y)
    self.restartDistortShader:send("distortion", self.restartEffect.distortion)
    self.restartDistortShader:send("size", self.restartEffect.size)
  end

  lg.setCanvas({ self.gameCanvas, stencil = true })
  if self.won then
    lg.clear(lerpColor(
      0, 0, 0, 0,
      0, 0.5, 0, 1,
      self.winEffect * 1.6
    ))
  else
    lg.clear(0, 0, 0, 0)
  end

  if self.restartEffect.enabled then
    self:drawNoiseBackground()
  end

  lg.push()
  lg.translate(self.cameraX + self.shakeAmount * love.math.random(), self.cameraY + self.shakeAmount * love.math.random())

  for _, c in ipairs(self.deathCrosses) do
    lg.push()
    lg.translate(c.x, c.y)
    lg.rotate(c.r)
    lg.setColor(1, 1, 1, c.a)
    lg.setLineWidth(c.lw)
    lg.line(-c.s, 0, c.s, 0)
    lg.line(0, -c.s, 0, c.s)
    lg.pop()
  end

  for _, o in ipairs(self.objects) do
    if o.draw then
      o:draw()
    else
      lg.setColor(o.color)
      lg.rectangle("fill", o.x, o.y, o.w, o.h)
    end

    if o.goal then
      if self.keysCount < self.level.neededKeys then
        -- locked
        lg.setColor(0, 0, 0, 0.5)
        lg.rectangle("fill", o.x, o.y, o.w, o.h)
        local remaining = self.level.neededKeys - self.keysCount
        lg.push()
        lg.translate(o.x + o.w / 2, o.y + o.h / 2)
        lg.rotate(love.timer.getTime())
        lg.setColor(o.color)
        if remaining == 1 then
          lg.circle("fill", tileSize / 5, 0, 4)
        elseif remaining == 2 then
          lg.setLineWidth(4)
          lg.line(-tileSize / 4, 0, tileSize / 4, 0)
        else
          lg.circle("fill", 0, 0, tileSize / 4, remaining)
        end
        lg.pop()
      else
        -- unlocked
        lg.setColor(o.color[1], o.color[2], o.color[3], (math.sin(love.timer.getTime() * 5) + 1) / 2 * 0.2 + 0.5)
        lg.rectangle("fill",
          o.x + math.sin(love.timer.getTime() * 1.5) * 5 - o.w * 0.15,
          o.y + math.cos(love.timer.getTime() * 1.5) * 5 - o.h * 0.15,
          o.w * 1.3, o.h * 1.3)
      end

      if self.goalTimer > 0 then
        lg.push()
        lg.setStencilTest("greater", 0)
        lg.stencil(function()
          lg.rectangle("fill", o.x, o.y, o.w, o.h)
        end, "replace", 1)
        lg.translate(o.x + o.w / 2, o.y + o.h / 2)
        lg.setColor(0, 0.5, 0)
        lg.arc("fill", "pie", 0, 0, o.w, 0, self.goalTimer / goalDuration * math.pi * 2)
        lg.setStencilTest()
        lg.pop()
      end
    elseif o == self.player and self.player.speed >= self.player.breakSpeed then
      lg.setColor(o.color[1], o.color[2], o.color[3], 0.3)
      lg.rectangle("fill", o.x - 5, o.y - 5, o.w + 10, o.h + 10)
    end
  end

  lg.pop()
  lg.setCanvas()

  lg.setCanvas(self.subCanvas)
  lg.clear(0, 0, 1, 1)
  local a = (love.timer.getTime() / 3) % (math.pi * 2)
  local d = math.sin(love.timer.getTime()) * 7
  lg.setColor(1, 1, 1, math.abs(d / 5) / 6)
  lg.draw(self.gameCanvas, math.cos(a) * d, math.sin(a) * d)
  lg.setColor(1, 1, 1)
  lg.setFont(titleFont)
  lg.print(self.level.title, self.textScrollX, lg.getHeight() - titleFont:getHeight() * titleScale, 0, titleScale)
  lg.setFont(timerFont)
  lg.setColor(0, 0, 0, 0.2)
  lg.push()
  lg.translate(5, 5)
  self:drawTimer()
  lg.pop()
  lg.setColor(1, 1, 1, 0.3)
  self:drawTimer()
  if self.won then
    lg.setFont(titleFont)
    lg.setColor(1, 1, 1)
    lg.print("YEAH\npressSpace", 40, 100, -0.1, 3)
  end
  lg.setCanvas()

  self.trailCanvas1, self.trailCanvas2 = self.trailCanvas2, self.trailCanvas1

  lg.setCanvas(self.trailCanvas2)
  lg.setColor(1, 1, 1)
  lg.draw(self.gameCanvas)
  lg.setCanvas()

  lg.setCanvas(self.trailCanvas1)
  lg.clear(0, 0, 0, 0)
  lg.setColor(1, 1, 1)
  if frameCount % 5 == 0 then
    quadDitherIndex = (quadDitherIndex + 1) % 4
    quadDitherShader:send("idx", quadDitherIndex)
    lg.setShader(quadDitherShader)
  end
  lg.draw(self.trailCanvas2)
  lg.setShader()
  lg.setCanvas()


  self:restartCrop()
  lg.setColor(1, 1, 1, 0.6)
  if self.restartEffect.enabled then
    lg.setShader(self.restartDistortShader)
  end
  lg.draw(self.trailCanvas2)
  lg.setShader()
  lg.setScissor()

  self:screenPass(self.invertShader)

  for _, shock in ipairs(self.shockwaves) do
    local life = shock.life / shock.lifetime
    local radius = lerp(shock.startRadius, shock.endRadius, life)
    self.shockwaveShader:send("minRadius", radius)
    self.shockwaveShader:send("maxRadius", radius + shock.width)
    self.shockwaveShader:send("mul", 0.03 * (1 - life))
    self.shockwaveShader:send("center", {
      (shock.x + self.cameraX) / self.gameCanvas:getWidth(),
      (shock.y + self.cameraY) / self.gameCanvas:getHeight()
    })
    self:screenPass(self.shockwaveShader)
  end

  if self.restartEffect.enabled then
    if self.restartEffect.direction == -1 then
      local h = math.max(self.restartEffect.y * lg.getHeight(), 0)
      lg.setCanvas(self.gameCanvas)
      lg.setScissor(0, 0, lg.getWidth(), h)
      lg.clear()
      lg.setColor(1, 1, 1)
      drawPremul(self.failCanvas)
      lg.setScissor()
      lg.setCanvas()
    end
    self:screenPass(self.restartDistortShader)
  end

  if not self.restartEffect.enabled then
    self:restartCrop()
    self:drawNoiseBackground()
    lg.setScissor()
  end

  lg.setColor(1, 1, 1)
  drawPremul(self.gameCanvas)
  if self.won then
    for i = 1, 5 do
      lg.setColor(1, 1, 1, 0.1)
      lg.draw(self.gameCanvas,
        lg.getWidth() / 2,
        lg.getHeight() / 2,
        i * self.winEffect * 0.5,
        (1 + i * self.winEffect) + (math.sin(love.timer.getTime() * 2 + i * 1.6) + 1) / 2 * self.winEffect,
        nil,
        self.gameCanvas:getWidth() / 2, self.gameCanvas:getHeight() / 2)
    end
  end

  if self.restartEffect.enabled then
    lg.setColor(0, 1, 0, self.restartEffect.y * 0.05)
    lg.rectangle("fill", 0, 0, self.gameCanvas:getDimensions())
  end

  frameCount = frameCount + 1
end

return game
