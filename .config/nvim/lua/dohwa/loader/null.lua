local Loader = require("dohwa.loader")

--- No plugins at all.
---
--- This is the acceptance test of the whole design rather than a curiosity:
--- with `DOHWA_LOADER=null` every module keeps its Features but only the
--- priority-0 native implementations exist, so what is left is the editor
--- Neovim can be on its own. If that is not usable, a fallback is missing.
---@class NullLoader : Loader
local NullLoader = Loader:extend("NullLoader")

function NullLoader:id()
  return "null"
end

function NullLoader:installs_plugins()
  return false
end

function NullLoader:install(specs)
  self.specs = specs
  self.dohwa:log("loader.null", "info", ("%d plugin specs ignored; native implementations only"):format(#specs))
  return true
end

function NullLoader:is_loaded()
  return false
end

return NullLoader
