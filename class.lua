---Returns a new instance of `T`, initialized with the given varargs.
---@generic T
---@param class T
---@param ... any
---@return T
function New(class, ...)
  local obj = setmetatable({}, class)
  obj:init(...)
  return obj
end

function Class()
  local t = {}
  t.__index = t
  t.new = New
  return t
end
