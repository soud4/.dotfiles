local Object = require("dohwa.object")

--- What is switched on, and where that decision is remembered.
---
--- Two layers: the profile file under `lua/profiles/`, which is the config you
--- keep in version control, and a small JSON state file that `:Dohwa disable`
--- writes, so toggling a module at runtime survives a restart without editing
--- any Lua.
---@class Profile : Object
---@field name string
---@field spec { default: boolean, loader: string, modules: table<string, boolean> }
---@field overrides table<string, boolean>
local Profile = Object:extend("Profile")

function Profile:init(name)
  self.name = name or "default"
  self.spec = { default = true, loader = "lazy", modules = {} }
  self.overrides = {}
  self.errors = {}
  self.forced_off = {}
  for _, name in ipairs(vim.split(vim.env.DOHWA_DISABLE or "", ",", { trimempty = true })) do
    self.forced_off[vim.trim(name)] = true
  end
  self:_load_spec()
  self:_load_overrides()
end

function Profile:_load_spec()
  local ok, spec = pcall(require, "profiles." .. self.name)
  if not ok then
    self.errors[#self.errors + 1] = ("profile '%s' not found: %s"):format(self.name, tostring(spec))
    return
  end
  self.spec = vim.tbl_extend("force", self.spec, spec or {})
end

function Profile:state_path()
  local dir = vim.fs.joinpath(vim.fn.stdpath("state"), "dohwa")
  return vim.fs.joinpath(dir, self.name .. ".json"), dir
end

function Profile:_load_overrides()
  local path = self:state_path()
  local fd = io.open(path, "r")
  if not fd then
    return
  end
  local raw = fd:read("*a")
  fd:close()
  local ok, decoded = pcall(vim.json.decode, raw)
  if ok and type(decoded) == "table" then
    self.overrides = decoded
  end
end

--- Runtime overrides beat the profile file; the profile file beats the
--- module's own `default`.
---@param name string
---@param module_default boolean|nil
---@return boolean
function Profile:is_enabled(name, module_default)
  -- DOHWA_DISABLE=a,b forces modules off for one run without touching any
  -- file. This is what the disable matrix uses to prove every module can be
  -- removed on its own.
  if self.forced_off[name] then
    return false
  end
  if self.overrides[name] ~= nil then
    return self.overrides[name]
  end
  if self.spec.modules[name] ~= nil then
    return self.spec.modules[name]
  end
  if module_default ~= nil then
    return module_default and self.spec.default
  end
  return self.spec.default
end

--- Persist a runtime decision. Passing nil clears the override.
function Profile:set(name, enabled)
  self.overrides[name] = enabled
  local path, dir = self:state_path()
  vim.fn.mkdir(dir, "p")
  local fd, err = io.open(path, "w")
  if not fd then
    return false, err
  end
  fd:write(vim.json.encode(self.overrides))
  fd:close()
  return true
end

function Profile:loader()
  return vim.env.DOHWA_LOADER or self.spec.loader or "lazy"
end

return Profile
