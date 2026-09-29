--- `:checkhealth dohwa` — the module graph, the feature arbitration and every
--- key the broker refused to apply, in one place.
local M = {}

local health = vim.health

local function report_modules(dohwa)
  health.start("modules")
  local active, disabled, skipped, errored = {}, {}, {}, {}
  for _, name in ipairs(dohwa:names()) do
    local module = dohwa.modules[name]
    local bucket = ({ active = active, disabled = disabled, skipped = skipped, error = errored })[module.state]
    table.insert(bucket or errored, module)
  end
  health.ok(("%d active: %s"):format(#active, table.concat(vim.tbl_map(function(m)
    return m.name
  end, active), ", ")))
  if #disabled > 0 then
    health.info(("%d disabled by profile: %s"):format(#disabled, table.concat(vim.tbl_map(function(m)
      return m.name
    end, disabled), ", ")))
  end
  for _, module in ipairs(skipped) do
    health.warn(("%s skipped — %s"):format(module.name, module.reason),
      { "its features fall back to the native implementation" })
  end
  for _, module in ipairs(errored) do
    health.error(("%s — %s"):format(module.name, module.reason or "unknown error"))
  end
  if #dohwa.cycle > 0 then
    health.error("dependency cycle: " .. table.concat(dohwa.cycle, " -> "))
  end
end

local function report_order(dohwa)
  health.start("load order")
  health.info(table.concat(dohwa.order, " -> "))
  health.info(("loader: %s · profile: %s · boot: %.1f ms")
    :format(dohwa.loader:id(), dohwa.profile.name, (dohwa.boot_ns or 0) / 1e6))
end

local function report_features(dohwa)
  health.start("features")
  local orphans = {}
  for _, name in ipairs(dohwa.registry:names()) do
    local feature = dohwa.registry:get(name)
    local winner = feature:winner()
    if not winner then
      if not feature.optional then
        orphans[#orphans + 1] = name
      end
    else
      local losers = vim.tbl_map(function(impl)
        return ("%s:%d"):format(impl.owner, impl.priority)
      end, feature:losers())
      local suffix = #losers > 0 and (" (over " .. table.concat(losers, ", ") .. ")") or ""
      health.info(("%-24s %s:%d%s"):format(name, winner.owner, winner.priority, suffix))
    end
  end
  if #orphans > 0 then
    health.error("features with no implementation at all: " .. table.concat(orphans, ", "),
      { "declare a native fallback so disabling the module stays safe" })
  else
    health.ok("every non-optional feature has an implementation")
  end
  local undeclared = dohwa.registry:undeclared()
  if #undeclared > 0 then
    health.warn("implemented but never declared: " .. table.concat(undeclared, ", "),
      { "either the declaring module is off, or the feature name is misspelled" })
  end
  for _, err in ipairs(dohwa.registry.errors) do
    health.error(("%s: %s"):format(err.owner, err.message))
  end
end

local function report_keys(dohwa)
  health.start("keys")
  local conflicts = dohwa.keys:conflicts()
  health.info(("%d mappings applied across %d namespaces")
    :format(#dohwa.keys.applied, #dohwa.keys:groups()))

  if #conflicts.rejected == 0 then
    health.ok("no rejected mappings")
  end
  for _, rejected in ipairs(conflicts.rejected) do
    local detail = rejected.detail or (rejected.holder and ("held by " .. rejected.holder)) or ""
    health.error(("%s: %s %s — %s"):format(
      rejected.owner or "?", rejected.mode or "", rejected.lhs, rejected.reason),
      { detail })
  end

  if #conflicts.shadows == 0 then
    health.ok("no prefix shadowing")
  end
  for _, shadow in ipairs(conflicts.shadows) do
    health.warn(("%s %s (%s) delays %s"):format(
      shadow.mode, shadow.lhs, shadow.owner, table.concat(shadow.shadowed, ", ")),
      { ("it only fires after 'timeoutlen' (%dms)"):format(vim.o.timeoutlen) })
  end
end

local function report_messages(dohwa)
  local problems = vim.tbl_filter(function(entry)
    return entry.level == "error" or entry.level == "warn"
  end, dohwa.messages)
  if #problems == 0 then
    return
  end
  health.start("log")
  for _, entry in ipairs(problems) do
    local fn = entry.level == "error" and health.error or health.warn
    fn(("%s: %s"):format(entry.source, entry.message))
  end
end

function M.check()
  local ok, dohwa = pcall(require, "dohwa")
  if not ok then
    return health.error("dohwa is not loadable: " .. tostring(dohwa))
  end
  if not dohwa.booted then
    return health.error("dohwa has not booted")
  end
  report_modules(dohwa)
  report_order(dohwa)
  report_features(dohwa)
  report_keys(dohwa)
  report_messages(dohwa)
end

return M
