local love = love
local lg = love.graphics

local w, h = 36, 36

local chaseDist = 48 * 4
local shookDuration = 1

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
  self.hurt = true
  self.quad = 1
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
    self.quad = 3
    local dx, dy = Normalize(player:midX() - self:midX(), player:midY() - self:midY())
    self.vx = self.vx + dx * 100 * dt
    self.vy = self.vy + dy * 100 * dt
  else
    self.chasing = false
  end
  if self.shookTimer > 0 then
    self.shookTimer = self.shookTimer - dt
    if self.shookTimer <= 0 then
      self.quad = 1
    end
  end
end

function bouncer:draw()
  lg.setColor(1, 1, 1)
  lg.draw(sheet,
    quads[self.quad],
    self.x + RandFloat(-self.shookTimer, self.shookTimer) * 2,
    self.y + RandFloat(-self.shookTimer, self.shookTimer) * 2)
end

return bouncer
