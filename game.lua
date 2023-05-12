local love = love
local lg = love.graphics

local bump = require "bump"
local flux = require "flux"

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

local titleFont = lg.newFont(24)
local titleScale = 3

local timerFont = lg.newFont(150)

local game = {}

function game:enter(_, level)
  self.tweens = flux.group()

  self.deathCrosses = {}

  self.gameCanvas = lg.newCanvas()
  self.subCanvas = lg.newCanvas()

  self.invertShader = lg.newShader [[
    vec4 lerp(vec4 a, vec4 b, float t) {
      return a + (b - a) * t;
    }

    uniform Image invertTexture;
    vec4 effect(vec4 color, Image texture, vec2 tc, vec2 sc) {
      vec4 pixel = Texel(texture, tc);
      vec4 inverted = vec4(1 - vec3(pixel), 1);
      return lerp(pixel, inverted, Texel(invertTexture, tc).r) * color;
    }
  ]]
  self.invertShader:send("invertTexture", self.subCanvas)

  self.scrollText = level.title
  self.textScrollX = 0
  self.textY = love.math.random(0, lg.getHeight() - titleFont:getHeight() * titleScale)

  self:startLevel(level)
end

function game:centerPos(o, x, y)
  return
      x * tileSize + tileSize / 2 - o.w / 2,
      y * tileSize + tileSize / 2 - o.h / 2
end

function game:startLevel(level)
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
      goal.x, goal.y = self:centerPos(goal, e.x, e.y)
      self:addObject(goal)
    else
      error("what entity type '" .. e.type .. "'????")
    end
  end

  self.player = {
    w = tileSize * .35,
    h = tileSize * .35,
    vx = 0,
    vy = 0,
    accel = 1,
    color = { 1, 1, 1 }
  }
  self.player.x, self.player.y = self:centerPos(self.player, level.playerX, level.playerY)

  self.dead = false
  self.restartTimer = nil

  self.startTime = love.timer.getTime()
  self.firstMoved = false

  self:addObject(self.player)
end

function game:addObject(obj)
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
  self.dead = true
  self.restartTimer = 1
  self:removeObject(self.player)

  local cross = {
    x = self.player.x + self.player.w / 2,
    y = self.player.y + self.player.h / 2,
    lw = self.player.w,
    s = self.player.w / 2,
    r = 0,
    a = 1,
  }
  self.tweens:to(cross, 0.5, { r = 0.5, lw = cross.lw / 2, s = tileSize / 2, a = 0.1 })
  table.insert(self.deathCrosses, cross)

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
  self.tweens:to(self, 2, {winEffect = 0.1})
end

function game:update(dt)
  if not self.dead and not self.won then
    for key, dir in pairs(moveDirs) do
      if love.keyboard.isDown(key) then
        self.player.vx = self.player.vx + self.player.accel * (dir.x or 0)
        self.player.vy = self.player.vy + self.player.accel * (dir.y or 0)
        self.firstMoved = true
      end
    end

    local cols
    self.player.x, self.player.y, cols = self.world:move(self.player, self.player.x + self.player.vx * dt,
      self.player.y + self.player.vy * dt, playerMoveFilter)

    self.touchingGoal = false
    for _, col in ipairs(cols) do
      if col.other.hurt then
        self:die()
        break
      end

      if col.other.goal then
        self.touchingGoal = true
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
  end

  if self.restartTimer then
    self.restartTimer = self.restartTimer - dt
    if self.restartTimer <= 0 then
      self:startLevel(self.level)
    end
  end

  self.textScrollX = self.textScrollX - dt * 200
  if self.textScrollX < -titleFont:getWidth(self.level.title) * titleScale then
    self.textScrollX = lg.getWidth()
    self.textY = love.math.random(0, lg.getHeight() - titleFont:getHeight() * titleScale)
  end

  self.tweens:update(dt)
end

function game:draw()
  lg.setCanvas({ self.gameCanvas, stencil = true })
  if self.won then
    lg.clear(0, 0.3, 0, 1)
  else
    lg.clear(0, 0, 0, 1)
  end

  lg.push()
  lg.translate(lg.getWidth() / 2 - self.level.width * tileSize / 2, lg.getHeight() / 2 - self.level.height * tileSize / 2)

  lg.setColor(0, 0, 1, 0.05)
  lg.rectangle("fill", 0, 0, self.level.width * tileSize, self.level.height * tileSize)

  for _, o in ipairs(self.objects) do
    lg.setColor(o.color)
    lg.rectangle("fill", o.x, o.y, o.w, o.h)

    if o.goal and self.goalTimer > 0 then
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
  end

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

  lg.pop()

  lg.setCanvas(self.subCanvas)
  lg.clear(0, 0, 1, 1)
  lg.setColor(1, 1, 1, 0.15)
  local a = (love.timer.getTime() / 3) % (math.pi * 2)
  local d = math.sin(love.timer.getTime()) * 5
  lg.draw(self.gameCanvas, math.cos(a) * d, math.sin(a) * d)
  lg.setColor(1, 1, 1)
  lg.setFont(titleFont)
  lg.print(self.level.title, self.textScrollX, lg.getHeight() - titleFont:getHeight() * titleScale, 0, titleScale)
  lg.setFont(timerFont)
  lg.setColor(1, 1, 1, 0.2)
  lg.printf(("%.2f"):format(self.levelTime), 0, lg.getHeight() / 2 - timerFont:getHeight() / 2, lg.getWidth(), "center")
  if self.won then
    lg.setFont(titleFont)
    lg.setColor(1, 1, 1)
    lg.print("YEAH\npressSpace", 40, 100, -0.1, 3)
  end
  lg.setCanvas()

  lg.setShader(self.invertShader)
  lg.setColor(1, 1, 1)
  lg.draw(self.gameCanvas)
  if self.won then
    for i = 1, 5 do
      lg.setColor(1, 1, 1, 0.1)
      lg.draw(self.gameCanvas, lg.getWidth() / 2, lg.getHeight() / 2, i * self.winEffect, (1 + i * self.winEffect) + (math.sin(love.timer.getTime() * 2 + i * 1.6) + 1) / 2 * self.winEffect, nil,
        self.gameCanvas:getWidth() / 2, self.gameCanvas:getHeight() / 2)
    end
  end
  lg.setShader()
end

return game
