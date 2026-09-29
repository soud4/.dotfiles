local Object = require("dohwa.object")

--- How plugins get onto the runtimepath. An interface, so lazy.nvim is one
--- implementation among others rather than the foundation of the config.
---
--- Contract for `install`: the loader receives plugin specs and is responsible
--- for arranging that each owning module's `setup(ctx)` runs once its plugin is
--- loaded. A loader that installs nothing simply never calls them, and every
--- Feature stays on the native implementation registered by `native(ctx)`.
---@class Loader : Object
---@field dohwa Dohwa
local Loader = Object:extend("Loader")

function Loader:init(dohwa)
  self.dohwa = dohwa
  self.specs = {}
end

---@return string
function Loader:id()
  return "abstract"
end

--- Whether modules should register their plugin-backed implementations at all.
---@return boolean
function Loader:installs_plugins()
  return true
end

---@param specs table[]
function Loader:install(specs)
  error(("loader '%s' does not implement install()"):format(self:id()))
end

---@param name string
---@return boolean
function Loader:is_loaded(name)
  return false
end

function Loader:stats()
  return { loader = self:id(), specs = #self.specs }
end

return Loader
