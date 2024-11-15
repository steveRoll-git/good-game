io.stdout:setvbuf("no")

DebugMode = arg[2] == "debug"
IS_DEBUG = os.getenv("LOCAL_LUA_DEBUGGER_VSCODE") == "1" and DebugMode
if IS_DEBUG then
  require("lldebugger").start()

  function love.errorhandler(msg)
    error(msg, 2)
  end
end

require "lib.class"

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

InterFont = "fonts/Inter-Regular.ttf"

local roomy = require "lib.roomy"
local game = require "states.game"

Manager = roomy.new()

function love.load(arg)
  local currentLevel = "levels.level1"
  if arg[1] == "debug" then
    DebugMode = true
    for i = 1, #arg do
      if arg[i] == "-level" then
        currentLevel = arg[i + 1]
      end
    end
  end
  Manager:hook()
  Manager:enter(game, require(currentLevel))
end
