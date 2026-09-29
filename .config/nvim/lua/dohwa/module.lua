local Object = require("dohwa.object")

--- One switchable unit of configuration.
---
--- A module is a declaration, never an imperative script. It exposes four
--- hooks, and which of them run is what makes disabling safe:
---
---   native(ctx)   always runs while the module is active. Declares its
---                 Features with their priority-0 native implementations,
---                 reserves its key namespace, binds keys to its own Features.
---   declare(ctx)  runs only when the module's plugins will actually be
---                 installed. Registers the better implementations as thunks.
---   plugins(ctx)  pure data handed to the Loader.
---   setup(ctx)    runs inside the plugin's own config(), so it stays lazy.
---
--- With the NullLoader, or when a module is skipped, `declare` and `setup`
--- never run and every Feature falls back to what `native` registered.
---@class Module : Object
---@field name string
---@field requires string[]
---@field optional string[]
---@field protected boolean
---@field state "pending"|"active"|"disabled"|"skipped"|"error"
local Module = Object:extend("Module")

local HOOKS = { "native", "declare", "plugins", "setup" }

---@param spec table
function Module:init(spec)
  assert(type(spec) == "table", "module spec must be a table")
  assert(type(spec.name) == "string", "module spec needs a name")
  self.name = spec.name
  self.description = spec.description or ""
  self.requires = spec.requires or {}
  self.optional = spec.optional or {}
  self.protected = spec.protected or false
  self.default = spec.default ~= false
  self.state = "pending"
  self.reason = nil
  for _, hook in ipairs(HOOKS) do
    if spec[hook] ~= nil then
      assert(type(spec[hook]) == "function", ("module '%s': %s must be a function"):format(self.name, hook))
      self[hook] = spec[hook]
    end
  end
end

function Module:has_plugins()
  return type(self.plugins) == "function"
end

function Module:is_active()
  return self.state == "active"
end

--- Run a hook with its context, converting an error into module state instead
--- of an aborted boot.
---@param hook string
---@param ctx Context
---@return boolean ok, any result
function Module:run(hook, ctx)
  local fn = self[hook]
  if type(fn) ~= "function" then
    return true, nil
  end
  local ok, result = pcall(fn, ctx)
  if not ok then
    self.state = "error"
    self.reason = ("%s(): %s"):format(hook, tostring(result))
    return false, result
  end
  return true, result
end

function Module:__tostring()
  return ("<Module %s [%s]>"):format(self.name, self.state)
end

--- Native-only unit. Protected by default: Dohwa refuses to disable it without
--- an explicit --force, because these carry the editor's floor behaviour.
---@class CoreModule : Module
local CoreModule = Module:extend("CoreModule")

function CoreModule:init(spec)
  spec = vim.tbl_extend("keep", spec, { protected = true })
  Module.init(self, spec)
end

--- A unit that contributes plugin specs to the active Loader.
---@class PluginModule : Module
local PluginModule = Module:extend("PluginModule")

return {
  Module = Module,
  CoreModule = CoreModule,
  PluginModule = PluginModule,
}
