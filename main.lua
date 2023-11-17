require "class"

function RandFloat(min, max)
  return min + (max - min) * love.math.random()
end

local roomy = require "roomy"
local game = require "game"

Manager = roomy.new()

function love.load()
  Manager:hook()
  Manager:enter(game, require "levels.level3")
end
