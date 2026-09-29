local Object = require("dohwa.object")

--- The handle a module receives. Everything a module is allowed to touch goes
--- through here, tagged with its name, so ownership is never ambiguous:
--- features, keys and autocommand groups are all attributable and revocable.
---@class Context : Object
---@field name string
---@field ui table shared visual tokens
local Context = Object:extend("Context")

---@param dohwa Dohwa
---@param module Module
function Context:init(dohwa, module)
  self.dohwa = dohwa
  self.module = module
  self.name = module.name
  self.ui = dohwa.ui
  self.plugins_available = false
end

-- Features ------------------------------------------------------------------

---@param name string
---@param opts { kind?: string, desc?: string, native?: function, optional?: boolean }
function Context:declare(name, opts)
  return self.dohwa.registry:declare(self.name, name, opts)
end

---@param name string
---@param priority integer higher wins; 0 is the native floor
---@param provider function thunk returning the implementation
function Context:implement(name, priority, provider)
  return self.dohwa.registry:implement(self.name, name, priority, provider)
end

--- Say that this module takes a `state` feature over, suppressing the native
--- implementation without replacing it with anything. Used when a plugin
--- installs its own handling from inside setup().
---@param name string
---@param priority integer|nil
function Context:override(name, priority)
  return self:implement(name, priority or 50, function()
    return function() end
  end)
end

function Context:feature(name)
  return self.dohwa.registry:get(name)
end

function Context:call(name, ...)
  return self.dohwa.registry:call(name, ...)
end

--- Read a `value` feature with a fallback used when nothing provides it.
function Context:value(name, default)
  return self.dohwa.registry:value(name, default)
end

-- Keys ----------------------------------------------------------------------

function Context:reserve(prefix, desc, opts)
  return self.dohwa.keys:reserve(self.name, prefix, desc, opts)
end

function Context:map(modes, lhs, rhs, opts)
  return self.dohwa.keys:claim(self.name, modes, lhs, rhs, opts)
end

--- Bind a key to a Feature instead of to an implementation.
function Context:slot(modes, lhs, feature, opts)
  return self.dohwa.keys:slot(self.name, modes, lhs, feature, opts)
end

function Context:toggle(letter, desc, fn)
  return self.dohwa.keys:toggle(self.name, letter, desc, fn)
end

--- Take a letter in the shared `]`/`[` namespace.
---@param letter string
---@param desc string
---@param opts { next?: function, prev?: function, external?: boolean }
function Context:jump(letter, desc, opts)
  return self.dohwa.keys:jump(self.name, letter, desc, opts)
end

--- Withdraw every key this module declared so far, to replace them. Does not
--- apply anything: the broker commits once, after every module has spoken.
function Context:revoke_keys()
  return self.dohwa.keys:revoke(self.name)
end

--- Take a letter in the shared `a`/`i` text-object namespace.
---@param letter string
---@param desc string
---@param opts { outer?: function, inner?: function, external?: boolean }
function Context:textobject(letter, desc, opts)
  return self.dohwa.keys:textobject(self.name, letter, desc, opts)
end

--- Declare a mapping the plugin installs itself, so it is still checked for
--- collisions and still shows up in the key listing.
function Context:external(modes, lhs, desc)
  return self.dohwa.keys:claim(self.name, modes, lhs, nil, { desc = desc, external = true })
end

-- Neovim primitives ---------------------------------------------------------

--- Namespaced augroup, so a module's autocommands can be wiped as a unit.
function Context:augroup(suffix)
  local name = ("dohwa.%s%s"):format(self.name, suffix and ("." .. suffix) or "")
  return vim.api.nvim_create_augroup(name, { clear = true })
end

function Context:autocmd(event, opts)
  opts = vim.tbl_extend("force", opts, { group = opts.group or self:augroup() })
  return vim.api.nvim_create_autocmd(event, opts)
end

---@param options table<string, any> set of vim options
function Context:opt(options)
  for key, value in pairs(options) do
    vim.opt[key] = value
  end
end

-- Introspection -------------------------------------------------------------

---@param name string
---@return boolean whether another module is active
function Context:has(name)
  local module = self.dohwa.modules[name]
  return module ~= nil and module:is_active()
end

--- Every reserved namespace, for modules that present the key model to the
--- user (which-key, and the native listing that replaces it).
function Context:groups(only_groups)
  return self.dohwa.keys:groups(only_groups)
end

--- Every applied mapping, optionally filtered by prefix.
function Context:mappings(prefix)
  return self.dohwa.keys:list(prefix)
end

function Context:log(message)
  self.dohwa:log(self.name, "info", message)
end

function Context:warn(message)
  self.dohwa:log(self.name, "warn", message)
end

return Context
