local love = love
local lg = love.graphics

local w, h = 36, 36

local chaseDist = 48 * 5
local shookDuration = 0.8
local normalSpeed = 45
local friction = 0.4
local slowAcceleration = 4

local font = lg.newFont(32)

local sheet = lg.newImage("images/bouncer.png")

local quads = {}
for i = 0, 2 do
  table.insert(quads, lg.newQuad(i * w, 0, w, h, sheet:getDimensions()))
end

local bouncer = Class()

function bouncer:init(game, x, y)
  self.game = game
  self.x, self.y = x, y
  self.w, self.h = w, h
  self.vx, self.vy = 32, 32
  self.speed = 0
  self.hurt = true
  self.shookTimer = 0
end

function bouncer:moveFilter(other)
  return "bounce"
end

function bouncer:onCollision(col)
  if col.normal.x ~= 0 then
    self.vx = -self.vx
  elseif col.normal.y ~= 0 then
    self.vy = -self.vy
  end
  self.quad = 2
  self.shookTimer = shookDuration
end

function bouncer:update(dt)
  local player = self.game.player
  if self.shookTimer <= 0 and Dist(self:midX(), self:midY(), player:midX(), player:midY()) <= chaseDist then
    self.chasing = true
    local dx, dy = Normalize(player:midX() - self:midX(), player:midY() - self:midY())
    self.vx = self.vx + dx * 100 * dt
    self.vy = self.vy + dy * 100 * dt
  else
    self.chasing = false
  end
  if self.shookTimer > 0 then
    self.shookTimer = self.shookTimer - dt
  end
  self.speed = math.sqrt(self.vx ^ 2 + self.vy ^ 2)
  if not self.chasing then
    if self.speed > normalSpeed then
      self.vx = self.vx * (1 / (1 + (dt * friction)))
      self.vy = self.vy * (1 / (1 + (dt * friction)))
    elseif self.speed < normalSpeed - 1 then
      local dx, dy = Normalize(self.vx, self.vy)
      self.vx = self.vx + dx * slowAcceleration * dt
      self.vy = self.vy + dy * slowAcceleration * dt
    end
  end
end

function bouncer:draw()
  lg.setColor(1, 1, 1)
  lg.draw(sheet,
    quads[
      self.chasing and 3 or (self.shookTimer > 0 and 2 or 1)
    ],
    self.x + RandFloat(-self.shookTimer, self.shookTimer) * 2,
    self.y + RandFloat(-self.shookTimer, self.shookTimer) * 2)
  if self.printSpeed then
    lg.setFont(font)
    lg.print(math.floor(self.speed), self.x, self.y)
  end
end

return bouncer
