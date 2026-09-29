local Object = require("dohwa.object")
local Feature = require("dohwa.feature")

--- Every Feature in the system, plus the bookkeeping that makes misuse visible
--- instead of silent: implementing an undeclared feature is recorded as an
--- error rather than throwing, so one bad module never aborts the boot.
---@class FeatureRegistry : Object
---@field features table<string, Feature>
---@field errors { owner: string, message: string }[]
local FeatureRegistry = Object:extend("FeatureRegistry")

function FeatureRegistry:init()
  self.features = {}
  self.errors = {}
end

function FeatureRegistry:fail(owner, message)
  self.errors[#self.errors + 1] = { owner = owner, message = message }
end

---@param owner string
---@param name string
---@param opts table
---@return Feature|nil
function FeatureRegistry:declare(owner, name, opts)
  local prior = self.features[name]
  if prior and prior.declared then
    self:fail(owner, ("feature '%s' already declared by '%s'"):format(name, prior.owner))
    return prior
  end
  opts = vim.tbl_extend("force", opts or {}, { owner = owner })
  local existing = self.features[name]
  local feature = Feature(name, opts)
  feature.declared = true
  -- A placeholder may already hold implementations registered before the
  -- declaration arrived; keep them.
  if existing then
    for _, impl in ipairs(existing.impls) do
      feature:implement(impl.owner, impl.priority, impl.provider)
    end
  end
  self.features[name] = feature
  return feature
end

function FeatureRegistry:get(name)
  return self.features[name]
end

function FeatureRegistry:has(name)
  return self.features[name] ~= nil
end

--- Implementing a feature nobody declared creates an optional placeholder
--- rather than failing. That keeps a provider and its consumer from having to
--- know about each other's lifetime: whichever is active first wins the race,
--- and disabling either one is still safe. Placeholders are flagged so a
--- misspelled name shows up in :checkhealth instead of vanishing.
function FeatureRegistry:implement(owner, name, priority, provider)
  local feature = self.features[name]
  if not feature then
    feature = Feature(name, { optional = true, owner = owner, desc = name })
    feature.declared = false
    self.features[name] = feature
  end
  return feature:implement(owner, priority, provider)
end

--- Features that only ever got implementations, never a declaration.
function FeatureRegistry:undeclared()
  local out = {}
  for _, name in ipairs(self:names()) do
    if self.features[name].declared == false then
      out[#out + 1] = name
    end
  end
  return out
end

--- Call a `callable` feature by name.
function FeatureRegistry:call(name, ...)
  local feature = self.features[name]
  if not feature then
    return
  end
  return feature:call(...)
end

--- Read a `value` feature, with a literal default when nothing provides it.
function FeatureRegistry:value(name, default)
  local feature = self.features[name]
  if not feature then
    return default
  end
  local v = feature:resolve()
  if v == nil then
    return default
  end
  return v
end

--- Apply every `state` feature. Called once, at the end of boot.
function FeatureRegistry:activate_states()
  local applied, failed = {}, {}
  for _, name in ipairs(self:names()) do
    local feature = self.features[name]
    if feature.kind == "state" then
      local ok, err = feature:activate()
      if ok then
        applied[#applied + 1] = name
      elseif err then
        failed[#failed + 1] = { name = name, err = err }
      end
    end
  end
  return applied, failed
end

function FeatureRegistry:revoke_owner(owner)
  for _, feature in pairs(self.features) do
    feature:revoke(owner)
  end
end

---@return string[] sorted feature names
function FeatureRegistry:names()
  local out = {}
  for name in pairs(self.features) do
    out[#out + 1] = name
  end
  table.sort(out)
  return out
end

return FeatureRegistry
