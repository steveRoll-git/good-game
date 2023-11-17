require "class"

function RandFloat(min, max)
  return min + (max - min) * love.math.random()
end

function Dist(x1, y1, x2, y2)
  return ((x2 - x1) ^ 2 + (y2 - y1) ^ 2) ^ 0.5
end

function Normalize(x, y)
  local len = Dist(0, 0, x, y)
  return x / len, y / len
end

local roomy = require "roomy"
local game = require "game"

Manager = roomy.new()

function love.load()
  Manager:hook()
  Manager:enter(game, require "levels.level3")
end
