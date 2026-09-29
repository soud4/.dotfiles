local Object = require("dohwa.object")
local Graph = require("dohwa.graph")
local Context = require("dohwa.context")
local Profile = require("dohwa.profile")
local KeyBroker = require("dohwa.keybroker")
local FeatureRegistry = require("dohwa.registry")
local M = require("dohwa.module")

--- The master object. Deliberately small: it owns the module table, the
--- dependency graph, the feature registry, the key broker and the boot
--- sequence, and nothing else. Options, mappings, autocommands and plugins all
--- live in modules, including the core ones and the plugin loader itself.
---@class Dohwa : Object
---@field modules table<string, Module>
---@field order string[]
---@field registry FeatureRegistry
---@field keys KeyBroker
---@field graph Graph
---@field profile Profile
---@field loader Loader
local Dohwa = Object:extend("Dohwa")

function Dohwa:init()
  self.modules = {}
  self.order = {}
  self.skipped = {}
  self.cycle = {}
  self.messages = {}
  self.contexts = {}
  self.graph = Graph()
  self.registry = FeatureRegistry()
  self.keys = KeyBroker(self.registry)
  self.ui = require("core.ui")
  self.booted = false
  self.started_at = vim.uv.hrtime()
end

function Dohwa:log(source, level, message)
  self.messages[#self.messages + 1] = { source = source, level = level, message = message }
end

-- Discovery -----------------------------------------------------------------

local function module_root()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "modules")
end

--- Every `lua/modules/**/*.lua` is a module; its path is its name.
--- `modules/editor/lsp.lua` is `editor.lsp`, and anything under `core/` is a
--- protected CoreModule.
function Dohwa:discover()
  local root = module_root()
  local files = vim.fn.globpath(root, "**/*.lua", false, true)
  table.sort(files)
  for _, file in ipairs(files) do
    local rel = file:sub(#root + 2):gsub("%.lua$", "")
    local name = rel:gsub("[/\\]", ".")
    local ok, spec = pcall(require, "modules." .. name)
    if not ok then
      self:log(name, "error", "could not be loaded: " .. tostring(spec))
    elseif type(spec) ~= "table" then
      self:log(name, "error", "must return a table")
    else
      spec = vim.tbl_extend("keep", spec, { name = name })
      local class = name:match("^core%.") and M.CoreModule
        or (spec.plugins and M.PluginModule or M.Module)
      local built, err = pcall(class, spec)
      if built then
        self.modules[name] = err
      else
        self:log(name, "error", "invalid spec: " .. tostring(err))
      end
    end
  end
  return self
end

-- Boot ----------------------------------------------------------------------

function Dohwa:_select_loader()
  local id = self.profile:loader()
  local ok, class = pcall(require, "dohwa.loader." .. id)
  if not ok then
    self:log("dohwa", "error", ("unknown loader '%s', falling back to null"):format(id))
    class = require("dohwa.loader.null")
  end
  return class(self)
end

function Dohwa:context(module)
  if not self.contexts[module.name] then
    self.contexts[module.name] = Context(self, module)
  end
  return self.contexts[module.name]
end

---@param opts { profile?: string }|nil
function Dohwa:boot(opts)
  opts = opts or {}
  if self.booted then
    return self
  end
  self.booted = true

  self:discover()
  self.profile = Profile(opts.profile or vim.env.DOHWA_PROFILE or "default")
  self.loader = self:_select_loader()

  -- 1. Which modules the profile wants.
  local enabled = {}
  for name, module in pairs(self.modules) do
    self.graph:add(name, module.requires, module.optional)
    if self.profile:is_enabled(name, module.default) then
      enabled[name] = true
    else
      module.state = "disabled"
      module.reason = "disabled by profile"
    end
  end

  -- 2. Resolve order and cascade hard-dependency failures.
  local dropped
  self.order, self.skipped, self.cycle, dropped = self.graph:resolve(enabled)
  if dropped then
    self:log("dohwa", "info", "optional dependency cycle broken; declaration order is arbitrary between those modules")
  end
  for name, reason in pairs(self.skipped) do
    self.modules[name].state = "skipped"
    self.modules[name].reason = reason
  end
  for _, name in ipairs(self.cycle) do
    self.modules[name].state = "error"
    self.modules[name].reason = "dependency cycle"
  end
  for _, name in ipairs(self.order) do
    self.modules[name].state = "active"
  end

  -- 3. Protected modules are the only ones allowed outside a reserved prefix.
  for _, name in ipairs(self.order) do
    if self.modules[name].protected then
      self.keys:allow_global(name)
    end
  end

  -- 4. Pass A: natives. Always runs for an active module, so the floor exists
  --    whether or not any plugin ever loads.
  local installs = self.loader:installs_plugins()
  for _, name in ipairs(self.order) do
    local module = self.modules[name]
    local ctx = self:context(module)
    ctx.plugins_available = installs and module:has_plugins()
    module:run("native", ctx)
  end

  -- 5. Pass B: plugin-backed implementations, registered as thunks so nothing
  --    is required yet.
  for _, name in ipairs(self.order) do
    local module = self.modules[name]
    if module:is_active() and (installs or not module:has_plugins()) then
      module:run("declare", self:context(module))
    end
  end

  -- 6. The whole key model is validated in one pass, then applied.
  self.keys:commit()

  -- 7. Hand the specs to the loader, which arranges for setup() to run when a
  --    plugin actually loads.
  self.loader:install(self:_collect_specs(installs))

  -- 8. State features (colorscheme, statusline) apply their winner.
  local _, failed = self.registry:activate_states()
  for _, item in ipairs(failed) do
    self:log(item.name, "error", "activation failed: " .. tostring(item.err))
  end

  require("dohwa.command").register(self)
  self.boot_ns = vim.uv.hrtime() - self.started_at
  return self
end

--- Collect plugin specs and attach each module's `setup` to its main spec.
--- A module that defines `setup` owns that spec's `config`: it must call the
--- plugin's own setup itself. Declaring both is an ownership conflict and is
--- reported rather than silently resolved.
function Dohwa:_collect_specs(installs)
  local specs = {}
  if not installs then
    return specs
  end
  for _, name in ipairs(self.order) do
    local module = self.modules[name]
    if module:is_active() and module:has_plugins() then
      local ctx = self:context(module)
      local ok, list = module:run("plugins", ctx)
      if ok and type(list) == "table" then
        if type(module.setup) == "function" and #list > 0 then
          local main = list[1]
          for _, spec in ipairs(list) do
            if spec.dohwa_main then
              main = spec
            end
          end
          if main.config then
            self:log(name, "error", "spec defines config() and the module defines setup(); setup() wins")
          end
          main.config = function()
            module:run("setup", ctx)
          end
        end
        vim.list_extend(specs, list)
      end
    end
  end
  return specs
end

-- Runtime control -----------------------------------------------------------

---@param name string
---@param force boolean|nil
---@return boolean ok, string message
function Dohwa:disable(name, force)
  local module = self.modules[name]
  if not module then
    return false, ("unknown module '%s'"):format(name)
  end
  if module.protected and not force then
    return false, ("'%s' is protected; use :Dohwa disable %s --force"):format(name, name)
  end
  local affected = self.graph:dependents(name)
  self.profile:set(name, false)
  self.registry:revoke_owner(name)
  self.keys:release(name)
  module.state = "disabled"
  module.reason = "disabled at runtime"
  local extra = #affected > 0 and (" · depends on it: " .. table.concat(affected, ", ")) or ""
  return true, ("'%s' disabled%s · restart to unload its plugins"):format(name, extra)
end

function Dohwa:enable(name)
  local module = self.modules[name]
  if not module then
    return false, ("unknown module '%s'"):format(name)
  end
  self.profile:set(name, true)
  return true, ("'%s' enabled · restart to load it"):format(name)
end

--- Explain a module's current state and what it hangs off.
function Dohwa:why(name)
  local module = self.modules[name]
  if not module then
    return ("unknown module '%s'"):format(name)
  end
  local lines = {
    ("%s — %s"):format(module.name, module.description),
    ("state    : %s%s"):format(module.state, module.reason and (" (" .. module.reason .. ")") or ""),
    ("requires : %s"):format(#module.requires > 0 and table.concat(module.requires, ", ") or "—"),
    ("optional : %s"):format(#module.optional > 0 and table.concat(module.optional, ", ") or "—"),
    ("needed by: %s"):format(#self.graph:dependents(name) > 0
      and table.concat(self.graph:dependents(name), ", ") or "—"),
    ("protected: %s"):format(tostring(module.protected)),
  }
  return table.concat(lines, "\n")
end

function Dohwa:names()
  local out = {}
  for name in pairs(self.modules) do
    out[#out + 1] = name
  end
  table.sort(out)
  return out
end

-- Single instance: `require("dohwa"):boot()`.
return Dohwa()
