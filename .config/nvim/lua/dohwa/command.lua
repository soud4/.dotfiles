local popup = require("dohwa.popup")

--- `:Dohwa <subcommand>` — the control surface for the module system.
local M = {}

local STATE_MARK = {
  active = "+",
  disabled = "-",
  skipped = "~",
  error = "!",
  pending = "?",
}

local function status_lines(dohwa)
  local lines = {
    ("loader   : %s"):format(dohwa.loader:id()),
    ("profile  : %s"):format(dohwa.profile.name),
    ("boot     : %.1f ms"):format((dohwa.boot_ns or 0) / 1e6),
    "",
    "  + active   - disabled   ~ skipped   ! error",
    "",
  }
  for _, name in ipairs(dohwa:names()) do
    local module = dohwa.modules[name]
    lines[#lines + 1] = ("  %s %-22s %s"):format(
      STATE_MARK[module.state] or "?",
      name,
      module.reason or module.description
    )
  end
  local conflicts = dohwa.keys:conflicts()
  if #conflicts.rejected > 0 or #conflicts.shadows > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("keys     : %d rejected · %d shadowed  (:checkhealth dohwa)")
      :format(#conflicts.rejected, #conflicts.shadows)
  end
  return lines
end

local function graph_lines(dohwa)
  local lines = { "load order (topological)", "" }
  for i, name in ipairs(dohwa.order) do
    local module = dohwa.modules[name]
    local deps = {}
    for _, dep in ipairs(module.requires) do
      deps[#deps + 1] = dep
    end
    for _, dep in ipairs(module.optional) do
      deps[#deps + 1] = dep .. "?"
    end
    lines[#lines + 1] = ("  %2d. %-22s %s"):format(i, name, #deps > 0 and ("<- " .. table.concat(deps, ", ")) or "")
  end
  if next(dohwa.skipped) then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "skipped"
    for name, reason in pairs(dohwa.skipped) do
      lines[#lines + 1] = ("  %-22s %s"):format(name, reason)
    end
  end
  return lines
end

local function feature_lines(dohwa)
  local lines = { "features (winner <- contenders)", "" }
  for _, name in ipairs(dohwa.registry:names()) do
    local feature = dohwa.registry:get(name)
    local winner = feature:winner()
    local losers = {}
    for _, impl in ipairs(feature:losers()) do
      losers[#losers + 1] = ("%s:%d"):format(impl.owner, impl.priority)
    end
    lines[#lines + 1] = ("  %-24s %-8s %-18s %s"):format(
      name,
      feature.kind,
      winner and ("%s:%d"):format(winner.owner, winner.priority) or "—",
      #losers > 0 and table.concat(losers, " ") or ""
    )
  end
  return lines
end

--- The native stand-in for which-key: everything the broker actually applied.
local function key_lines(dohwa, prefix)
  local lines = {}
  local groups = dohwa.keys:groups()
  if not prefix and #groups > 0 then
    lines[#lines + 1] = "namespaces"
    for _, group in ipairs(groups) do
      lines[#lines + 1] = ("  %-14s %-24s %s"):format(group.prefix, group.desc, group.owner)
    end
    lines[#lines + 1] = ""
  end
  lines[#lines + 1] = prefix and ("mappings under " .. prefix) or "mappings"
  for _, map in ipairs(dohwa.keys:list(prefix)) do
    lines[#lines + 1] = ("  %-3s %-16s %-34s %s"):format(map.mode, map.lhs, map.desc or "", map.owner)
  end
  return lines
end

local SUBCOMMANDS = {
  status = function(dohwa)
    popup.show(status_lines(dohwa), { title = "Dohwa" })
  end,
  graph = function(dohwa)
    popup.show(graph_lines(dohwa), { title = "Dohwa · graph" })
  end,
  features = function(dohwa)
    popup.show(feature_lines(dohwa), { title = "Dohwa · features" })
  end,
  keys = function(dohwa, args)
    popup.show(key_lines(dohwa, args[1]), { title = "Dohwa · keys" })
  end,
  log = function(dohwa)
    local lines = {}
    for _, entry in ipairs(dohwa.messages) do
      lines[#lines + 1] = ("  [%s] %-20s %s"):format(entry.level, entry.source, entry.message)
    end
    popup.show(#lines > 0 and lines or { "  nothing logged" }, { title = "Dohwa · log" })
  end,
  why = function(dohwa, args)
    if not args[1] then
      return vim.notify("usage: :Dohwa why <module>", vim.log.levels.WARN)
    end
    popup.show(vim.split(dohwa:why(args[1]), "\n"), { title = "Dohwa · why" })
  end,
  disable = function(dohwa, args)
    local force = vim.tbl_contains(args, "--force")
    local ok, message = dohwa:disable(args[1], force)
    vim.notify(message, ok and vim.log.levels.INFO or vim.log.levels.ERROR)
  end,
  enable = function(dohwa, args)
    local ok, message = dohwa:enable(args[1])
    vim.notify(message, ok and vim.log.levels.INFO or vim.log.levels.ERROR)
  end,
}

function M.register(dohwa)
  vim.api.nvim_create_user_command("Dohwa", function(cmd)
    local args = cmd.fargs
    local name = table.remove(args, 1) or "status"
    local handler = SUBCOMMANDS[name]
    if not handler then
      return vim.notify(("unknown subcommand '%s'"):format(name), vim.log.levels.ERROR)
    end
    handler(dohwa, args)
  end, {
    nargs = "*",
    desc = "Dohwa module system",
    complete = function(lead, line)
      local parts = vim.split(line, "%s+")
      if #parts <= 2 then
        return vim.tbl_filter(function(name)
          return name:find(lead, 1, true) == 1
        end, vim.tbl_keys(SUBCOMMANDS))
      end
      if parts[2] == "why" or parts[2] == "enable" or parts[2] == "disable" then
        return vim.tbl_filter(function(name)
          return name:find(lead, 1, true) == 1
        end, dohwa:names())
      end
      return {}
    end,
  })
end

return M
