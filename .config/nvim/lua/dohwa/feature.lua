local Object = require("dohwa.object")

--- A named capability with several implementations ranked by priority.
---
--- This single abstraction covers three things that are usually three separate
--- mechanisms: native fallbacks (priority 0, declared by the owner and never
--- removable), global key slots (a Feature that a key is bound to), and
--- cross-module capabilities (`lsp.capabilities`).
---
--- Providers are thunks. They run at most once, on first resolve, which is what
--- lets an implementation `require()` a plugin without forcing it to load at
--- startup. A provider that throws is discarded and the next one down wins, so
--- a broken plugin degrades instead of breaking the editor.
---@class Feature : Object
---@field name string
---@field kind "callable"|"value"|"state"
---@field desc string
---@field optional boolean   no native floor: may resolve to nil
---@field impls { priority: integer, owner: string, provider: function }[]
local Feature = Object:extend("Feature")

---@param name string
---@param opts { kind?: string, desc?: string, native?: function, optional?: boolean, owner?: string }
function Feature:init(name, opts)
  opts = opts or {}
  self.name = name
  self.kind = opts.kind or "callable"
  self.desc = opts.desc or name
  self.optional = opts.optional or false
  self.owner = opts.owner or "core"
  self.impls = {}
  self._resolved = nil
  self._failed = {}
  if opts.native then
    self:implement(self.owner, 0, opts.native)
  end
end

--- Wrap a ready-made value as a provider thunk.
function Feature.const(value)
  return function()
    return value
  end
end

---@param owner string
---@param priority integer  0 is the native floor; higher wins
---@param provider function thunk returning the implementation
function Feature:implement(owner, priority, provider)
  assert(type(provider) == "function", ("feature '%s': provider must be a function"):format(self.name))
  self.impls[#self.impls + 1] = { priority = priority, owner = owner, provider = provider }
  table.sort(self.impls, function(a, b)
    if a.priority == b.priority then
      return a.owner < b.owner
    end
    return a.priority > b.priority
  end)
  self._resolved = nil
  return self
end

--- Drop every implementation contributed by a module (used when disabling it).
function Feature:revoke(owner)
  local kept = {}
  for _, impl in ipairs(self.impls) do
    if impl.owner ~= owner then
      kept[#kept + 1] = impl
    end
  end
  self.impls = kept
  self._resolved = nil
end

--- The implementation entry currently in charge, or nil.
function Feature:winner()
  for _, impl in ipairs(self.impls) do
    if not self._failed[impl] then
      return impl
    end
  end
end

--- Implementations that lost the arbitration, best first.
function Feature:losers()
  local out, seen_winner = {}, false
  for _, impl in ipairs(self.impls) do
    if self._failed[impl] then
      out[#out + 1] = impl
    elseif seen_winner then
      out[#out + 1] = impl
    else
      seen_winner = true
    end
  end
  return out
end

--- Run the winning provider and memoize. A failing provider is marked and the
--- next implementation is tried, all the way down to the native floor.
function Feature:resolve()
  if self._resolved ~= nil then
    return self._resolved
  end
  while true do
    local impl = self:winner()
    if not impl then
      return nil
    end
    local ok, value = pcall(impl.provider)
    if ok and value ~= nil then
      self._resolved = value
      return value
    end
    self._failed[impl] = ok and "provider returned nil" or tostring(value)
  end
end

--- Invoke a `callable` feature. No-op when nothing implements it.
function Feature:call(...)
  local fn = self:resolve()
  if type(fn) == "function" then
    return fn(...)
  end
end

--- Apply a `state` feature once. Only the winner ever runs.
function Feature:activate()
  if self.kind ~= "state" then
    return
  end
  local fn = self:resolve()
  if type(fn) == "function" then
    local ok, err = pcall(fn)
    if not ok then
      return false, err
    end
    return true
  end
  return false
end

function Feature:__tostring()
  local impl = self:winner()
  return ("<Feature %s -> %s>"):format(self.name, impl and impl.owner or "none")
end

return Feature
