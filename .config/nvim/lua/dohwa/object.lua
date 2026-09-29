--- Minimal class system used by every Dohwa component.
---
--- Classes are created with `Base:extend("Name")` and instantiated by calling
--- the class itself: `local g = Graph()`. Subclasses inherit fields through the
--- metatable chain, so `Module` methods stay available on `CoreModule`.

---@class Object
---@field __name string
---@field super Object|nil
local Object = {}
Object.__index = Object
Object.__name = "Object"

--- Called by `new`. Subclasses override this instead of `new`.
function Object:init(...) end

function Object:__tostring()
  return ("<%s>"):format(self.__name or "Object")
end

--- Create a subclass.
---@param name string
---@return table
function Object:extend(name)
  local cls = {}
  -- Metamethods are looked up on the metatable itself, never through __index,
  -- so they have to be copied down into each subclass explicitly.
  for k, v in pairs(self) do
    if type(k) == "string" and k:sub(1, 2) == "__" then
      cls[k] = v
    end
  end
  cls.__index = cls
  cls.__name = name
  cls.super = self
  return setmetatable(cls, {
    __index = self,
    __call = function(c, ...)
      return c:new(...)
    end,
  })
end

--- Instantiate. Prefer `MyClass(...)` over `MyClass:new(...)`.
function Object:new(...)
  local obj = setmetatable({}, self)
  obj:init(...)
  return obj
end

--- Walks the inheritance chain.
---@param cls table
---@return boolean
function Object:is_a(cls)
  local c = getmetatable(self)
  while c do
    if c == cls then
      return true
    end
    c = rawget(c, "super")
  end
  return false
end

return setmetatable(Object, {
  __call = function(c, ...)
    return c:new(...)
  end,
})
