local Object = require("dohwa.object")

--- Dependency DAG over module names.
---
--- Two edge kinds, with deliberately different semantics:
---   * `requires` (hard) — a missing dependency disables the dependent, and the
---     effect cascades transitively. This is what keeps integrity.
---   * `optional` (soft) — never disables anything. It only constrains the
---     declaration order so a capability is registered before a consumer looks
---     for it.
---@class Graph : Object
---@field nodes table<string, { requires: string[], optional: string[] }>
local Graph = Object:extend("Graph")

function Graph:init()
  self.nodes = {}
end

---@param name string
---@param requires string[]|nil
---@param optional string[]|nil
function Graph:add(name, requires, optional)
  self.nodes[name] = { requires = requires or {}, optional = optional or {} }
end

function Graph:has(name)
  return self.nodes[name] ~= nil
end

--- Every module that would break if `name` went away, transitively.
--- Only hard edges are followed: optional dependents survive on their fallback.
---@param name string
---@return string[]
function Graph:dependents(name)
  local seen, out, queue = {}, {}, { name }
  while #queue > 0 do
    local current = table.remove(queue)
    for other, node in pairs(self.nodes) do
      if not seen[other] then
        for _, req in ipairs(node.requires) do
          if req == current then
            seen[other] = true
            out[#out + 1] = other
            queue[#queue + 1] = other
            break
          end
        end
      end
    end
  end
  table.sort(out)
  return out
end

--- Resolve a load order for the requested set.
---@param enabled table<string, boolean>
---@return string[] order      topologically sorted, deterministic
---@return table<string, string> skipped  name -> human reason
---@return string[] cycle      names left over when a cycle exists
function Graph:resolve(enabled)
  local active, skipped = {}, {}
  for name in pairs(self.nodes) do
    if enabled[name] then
      active[name] = true
    end
  end

  -- Cascade: repeat until no further module loses a hard dependency.
  local changed = true
  while changed do
    changed = false
    for name in pairs(active) do
      for _, req in ipairs(self.nodes[name].requires) do
        if not active[req] then
          local why = self.nodes[req] and (enabled[req] and "skipped" or "disabled") or "unknown"
          skipped[name] = ("requires '%s' (%s)"):format(req, why)
          active[name] = nil
          changed = true
          break
        end
      end
    end
  end

  local order, cycle = self:_sort(active, true)
  if #cycle > 0 then
    -- A cycle made only of optional edges is not a real one: those edges exist
    -- to order declarations, not to express need. Drop them and sort again, so
    -- two modules that each prefer the other still both load.
    local hard_order, hard_cycle = self:_sort(active, false)
    if #hard_cycle == 0 then
      return hard_order, skipped, {}, true
    end
    return hard_order, skipped, hard_cycle
  end
  return order, skipped, cycle
end

--- Kahn's algorithm. Names are sorted at every step so the order never depends
--- on Lua's hash iteration order.
---@param active table<string, boolean>
---@param use_optional boolean
---@return string[] order, string[] cycle
function Graph:_sort(active, use_optional)
  local indegree, dependents = {}, {}
  local names = {}
  for name in pairs(active) do
    names[#names + 1] = name
    indegree[name] = 0
    dependents[name] = {}
  end
  table.sort(names)

  for _, name in ipairs(names) do
    local node = self.nodes[name]
    local edges = {}
    for _, dep in ipairs(node.requires) do
      edges[dep] = true
    end
    if use_optional then
      for _, dep in ipairs(node.optional) do
        if active[dep] then
          edges[dep] = true
        end
      end
    end
    for dep in pairs(edges) do
      if active[dep] then
        indegree[name] = indegree[name] + 1
        table.insert(dependents[dep], name)
      end
    end
  end

  local ready, order = {}, {}
  for _, name in ipairs(names) do
    if indegree[name] == 0 then
      ready[#ready + 1] = name
    end
  end

  while #ready > 0 do
    table.sort(ready)
    local name = table.remove(ready, 1)
    order[#order + 1] = name
    local children = dependents[name]
    table.sort(children)
    for _, child in ipairs(children) do
      indegree[child] = indegree[child] - 1
      if indegree[child] == 0 then
        ready[#ready + 1] = child
      end
    end
  end

  local cycle = {}
  if #order < #names then
    for _, name in ipairs(names) do
      if indegree[name] > 0 then
        cycle[#cycle + 1] = name
      end
    end
  end

  return order, cycle
end

return Graph
