local Object = require("dohwa.object")
local KeyTrie = require("dohwa.keytrie")

--- Ownership and arbitration for every key in the config.
---
--- Two rules, and they are what make cross-module collisions structurally
--- impossible rather than merely unlikely:
---
---   1. STRICT NAMESPACES. A module may only map below a prefix it reserved.
---      Anything else is rejected. Only privileged (protected core) modules may
---      touch the global namespace.
---   2. SLOTS. Global keys such as `gd` or `K` belong to core, which binds them
---      to a *Feature* rather than to an implementation. Modules compete by
---      implementing the feature, never by naming the key. A module therefore
---      cannot collide on a global key, because it never mentions one.
---
--- Nothing reaches `vim.keymap.set` until the complete model has been validated.
---@class KeyBroker : Object
---@field entries table[]
---@field reservations table[]
---@field rejected table[]
local KeyBroker = Object:extend("KeyBroker")

local PRIORITY_DEFAULT = 50

function KeyBroker:init(registry)
  self.registry = registry
  self.entries = {}
  self.reservations = {}
  self.rejected = {}
  self.applied = {}
  self.privileged = {}
  self.tries = {}
  self.duplicates = {}
  self.shadows = {}
  self.toggle_prefix = nil
  self.toggle_owner = nil
end

function KeyBroker:allow_global(owner)
  self.privileged[owner] = true
end

function KeyBroker:reject(reason, detail)
  self.rejected[#self.rejected + 1] = vim.tbl_extend("force", { reason = reason }, detail or {})
end

--- Claim exclusive ownership of a key prefix.
---@param owner string
---@param prefix string
---@param desc string
---@param opts { toggles?: boolean }|nil
function KeyBroker:reserve(owner, prefix, desc, opts)
  opts = opts or {}
  -- Two reservations of the same prefix only clash when their modes overlap;
  -- `[` in insert mode and `[` in normal mode are different namespaces.
  local function overlaps(a, b)
    if not a or not b then
      return true -- nil means every mode
    end
    for _, mode in ipairs(a) do
      if vim.tbl_contains(b, mode) then
        return true
      end
    end
    return false
  end

  for _, existing in ipairs(self.reservations) do
    if existing.prefix == prefix and existing.owner ~= owner and overlaps(existing.modes, opts.modes) then
      self:reject("reservation taken", {
        owner = owner,
        lhs = prefix,
        holder = existing.owner,
        detail = ("modes: %s"):format(existing.modes and table.concat(existing.modes, ",") or "all"),
      })
      return false
    end
  end
  self.reservations[#self.reservations + 1] = {
    owner = owner,
    prefix = prefix,
    desc = desc,
    modes = opts.modes, -- nil means every mode
  }
  if opts.toggles then
    self.toggle_prefix, self.toggle_owner = prefix, owner
  end
  if opts.jumps then
    self.jump_prefixes, self.jump_owner = opts.jumps, owner
  end
  if opts.textobjects then
    self.textobject_prefixes, self.textobject_owner = opts.textobjects, owner
  end
  return true
end

local function as_list(v)
  if type(v) == "table" then
    return v
  end
  return { v }
end

--- Map a key to a concrete implementation, inside the caller's namespace.
function KeyBroker:claim(owner, modes, lhs, rhs, opts)
  opts = opts or {}
  self.entries[#self.entries + 1] = {
    kind = "map",
    owner = owner,
    origin = opts.origin or owner,
    modes = as_list(modes),
    lhs = lhs,
    rhs = rhs,
    desc = opts.desc,
    priority = opts.priority or PRIORITY_DEFAULT,
    -- An external claim is validated like any other but applied by the plugin
    -- itself. Without this, mappings a plugin installs from inside its own
    -- setup() would be invisible to conflict detection.
    external = opts.external or false,
    buffer = opts.buffer,
    expr = opts.expr,
    silent = opts.silent ~= false,
    remap = opts.remap,
  }
end

--- Bind a key to a Feature. The key is resolved at press time, so whichever
--- module currently wins the feature is the one that runs.
function KeyBroker:slot(owner, modes, lhs, feature, opts)
  opts = opts or {}
  self.entries[#self.entries + 1] = {
    kind = "slot",
    owner = owner,
    origin = owner,
    modes = as_list(modes),
    lhs = lhs,
    feature = feature,
    desc = opts.desc,
    priority = opts.priority or PRIORITY_DEFAULT,
    silent = opts.silent ~= false,
  }
end

--- Register one letter under the shared toggle prefix. Duplicate letters are
--- refused on the spot, naming both modules.
function KeyBroker:toggle(owner, letter, desc, fn)
  if not self.toggle_prefix then
    self:reject("no toggle namespace", { owner = owner, lhs = letter })
    return false
  end
  local lhs = self.toggle_prefix .. letter
  for _, entry in ipairs(self.entries) do
    if entry.lhs == lhs then
      self:reject("toggle letter taken", { owner = owner, lhs = lhs, holder = entry.origin })
      return false
    end
  end
  self:claim(self.toggle_owner, "n", lhs, fn, { desc = desc, origin = owner })
  return true
end

--- Register one letter in the shared `]`/`[` jump namespace. Same contract as
--- toggles: the letter is exclusive and a second taker is refused by name.
---@param owner string
---@param letter string
---@param desc string
---@param opts { next?: function, prev?: function, external?: boolean }
function KeyBroker:jump(owner, letter, desc, opts)
  if not self.jump_prefixes then
    self:reject("no jump namespace", { owner = owner, lhs = letter })
    return false
  end
  opts = opts or {}
  local forward, backward = self.jump_prefixes[1] .. letter, self.jump_prefixes[2] .. letter
  for _, entry in ipairs(self.entries) do
    if entry.lhs == forward or entry.lhs == backward then
      self:reject("jump letter taken", { owner = owner, lhs = forward, holder = entry.origin })
      return false
    end
  end
  local shared = { origin = owner, external = opts.external }
  self:claim(self.jump_owner, "n", forward,
    opts.next, vim.tbl_extend("force", shared, { desc = "Next " .. desc }))
  self:claim(self.jump_owner, "n", backward,
    opts.prev, vim.tbl_extend("force", shared, { desc = "Previous " .. desc }))
  return true
end

--- Register one letter in the shared `a`/`i` text-object namespace, in
--- operator-pending and visual modes only.
---@param owner string
---@param letter string
---@param desc string
---@param opts { outer?: function, inner?: function, external?: boolean }
function KeyBroker:textobject(owner, letter, desc, opts)
  if not self.textobject_prefixes then
    self:reject("no text-object namespace", { owner = owner, lhs = letter })
    return false
  end
  opts = opts or {}
  local outer, inner = self.textobject_prefixes[1] .. letter, self.textobject_prefixes[2] .. letter
  for _, entry in ipairs(self.entries) do
    if entry.lhs == outer or entry.lhs == inner then
      self:reject("text-object letter taken", { owner = owner, lhs = inner, holder = entry.origin })
      return false
    end
  end
  local shared = { origin = owner, external = opts.external }
  local modes = { "o", "x" }
  if opts.outer or opts.external then
    self:claim(self.textobject_owner, modes, outer,
      opts.outer, vim.tbl_extend("force", shared, { desc = "a " .. desc }))
  end
  if opts.inner or opts.external then
    self:claim(self.textobject_owner, modes, inner,
      opts.inner, vim.tbl_extend("force", shared, { desc = "inner " .. desc }))
  end
  return true
end

function KeyBroker:_trie(mode)
  if not self.tries[mode] then
    local trie = KeyTrie(mode)
    for _, res in ipairs(self.reservations) do
      if not res.modes or vim.tbl_contains(res.modes, mode) then
        trie:reserve(res.prefix, res)
      end
    end
    self.tries[mode] = trie
  end
  return self.tries[mode]
end

--- Rule 1: the key must sit inside a namespace the owner holds, unless the
--- owner is privileged.
function KeyBroker:_namespace_ok(entry, mode)
  local reservation = self:_trie(mode):covering_reservation(entry.lhs)
  if reservation and reservation.owner == entry.owner then
    return true
  end
  -- Protected core modules are the authority over the global namespace and are
  -- not bound by anyone else's reservation.
  if self.privileged[entry.owner] then
    return true
  end
  if reservation then
    return false, ("'%s' is reserved by %s"):format(reservation.prefix, reservation.owner)
  end
  return false, "global namespace: reserve a prefix or use a core slot"
end

--- Validate the whole model, then apply what survived.
---@return table[] rejected
function KeyBroker:commit()
  for _, applied in ipairs(self.applied) do
    if not applied.external then
      pcall(vim.keymap.del, applied.mode, applied.lhs, applied.opts)
    end
  end
  self.applied = {}
  self.tries = {}
  self.rejected = vim.tbl_filter(function(r)
    return r.reason == "reservation taken"
      or r.reason == "toggle letter taken"
      or r.reason == "jump letter taken"
      or r.reason == "text-object letter taken"
  end, self.rejected)

  -- Pass 1: namespace check, per mode.
  local accepted = {}
  for _, entry in ipairs(self.entries) do
    for _, mode in ipairs(entry.modes) do
      -- External claims describe what a plugin maps on its own. They are not
      -- applied here, so the namespace rule has nothing to protect; they still
      -- take part in duplicate and shadow analysis, which is the whole point of
      -- declaring them.
      local ok, why = true, nil
      if not entry.external then
        ok, why = self:_namespace_ok(entry, mode)
      end
      if ok then
        accepted[#accepted + 1] = { entry = entry, mode = mode }
      else
        self:reject("namespace violation", {
          owner = entry.origin,
          lhs = entry.lhs,
          mode = mode,
          detail = why,
        })
      end
    end
  end

  -- Pass 2: build the tries and look for duplicates and prefix shadows.
  for _, item in ipairs(accepted) do
    self:_trie(item.mode):claim(item.entry.lhs, {
      owner = item.entry.origin,
      priority = item.entry.priority,
      entry = item.entry,
    })
  end

  self.duplicates, self.shadows = {}, {}
  local loser = {}
  for mode, trie in pairs(self.tries) do
    local duplicates, shadows = trie:analyze()
    for _, dup in ipairs(duplicates) do
      table.sort(dup.claims, function(a, b)
        if a.priority == b.priority then
          return a.owner < b.owner
        end
        return a.priority > b.priority
      end)
      self.duplicates[#self.duplicates + 1] = dup
      for i = 2, #dup.claims do
        loser[dup.claims[i].entry] = { mode = mode, winner = dup.claims[1].owner }
        self:reject("duplicate mapping", {
          owner = dup.claims[i].owner,
          lhs = dup.lhs,
          mode = mode,
          holder = dup.claims[1].owner,
        })
      end
    end
    -- A shadow is a latency bug, not an ownership conflict: both mappings are
    -- applied, but the short one only fires after 'timeoutlen'. Reported, kept.
    vim.list_extend(self.shadows, shadows)
  end

  -- Pass 3: apply.
  for _, item in ipairs(accepted) do
    local entry = item.entry
    if entry.external then
      self.applied[#self.applied + 1] = {
        mode = item.mode,
        lhs = entry.lhs,
        desc = (entry.desc or "") ~= "" and (entry.desc .. " (plugin)") or "(plugin)",
        owner = entry.origin,
        external = true,
      }
    elseif not loser[entry] then
      local rhs, desc = entry.rhs, entry.desc
      if entry.kind == "slot" then
        local registry, name = self.registry, entry.feature
        rhs = function()
          return registry:call(name)
        end
        local feature = registry:get(name)
        desc = desc or (feature and feature.desc) or name
      end
      local opts = {
        desc = desc,
        silent = entry.silent,
        expr = entry.expr,
        remap = entry.remap,
        buffer = entry.buffer,
      }
      local ok, err = pcall(vim.keymap.set, item.mode, entry.lhs, rhs, opts)
      if ok then
        self.applied[#self.applied + 1] = {
          mode = item.mode,
          lhs = entry.lhs,
          desc = desc,
          owner = entry.origin,
          opts = entry.buffer and { buffer = entry.buffer } or nil,
        }
      else
        self:reject("apply failed", { owner = entry.origin, lhs = entry.lhs, detail = tostring(err) })
      end
    end
  end

  return self.rejected
end

--- Drop everything a module owns, without re-applying. Used while the model is
--- still being built, when a module replaces its own declarations.
function KeyBroker:revoke(owner)
  self.entries = vim.tbl_filter(function(e)
    return e.owner ~= owner and e.origin ~= owner
  end, self.entries)
  self.reservations = vim.tbl_filter(function(r)
    return r.owner ~= owner
  end, self.reservations)
end

--- Drop everything a module owns and re-arbitrate, so a freed prefix becomes
--- available to whoever wanted it.
function KeyBroker:release(owner)
  self:revoke(owner)
  return self:commit()
end

--- Reservations, for which-key and for the native key listing.
---
--- `only_groups` keeps the ones that behave like a menu: a prefix with at
--- least one mapping strictly below it. It filters out single-key namespaces
--- such as the auto-pair characters, which are reservations for ownership
--- purposes but would be noise in a hint panel.
---@param only_groups boolean|nil
function KeyBroker:groups(only_groups)
  local out = {}
  for _, reservation in ipairs(self.reservations) do
    local keep = true
    if only_groups then
      -- Insert-mode-only namespaces are ownership bookkeeping, not a menu.
      local insert_only = reservation.modes ~= nil
        and #reservation.modes == 1
        and reservation.modes[1] == "i"
      keep = false
      if not insert_only then
        for _, applied in ipairs(self.applied) do
          if #applied.lhs > #reservation.prefix
            and applied.lhs:sub(1, #reservation.prefix) == reservation.prefix
          then
            keep = true
            break
          end
        end
      end
    end
    if keep then
      out[#out + 1] = vim.deepcopy(reservation)
    end
  end
  table.sort(out, function(a, b)
    return a.prefix < b.prefix
  end)
  return out
end

--- Applied mappings, optionally filtered by prefix.
function KeyBroker:list(prefix)
  local out = {}
  for _, applied in ipairs(self.applied) do
    if not prefix or applied.lhs:sub(1, #prefix) == prefix then
      out[#out + 1] = applied
    end
  end
  table.sort(out, function(a, b)
    if a.lhs == b.lhs then
      return a.mode < b.mode
    end
    return a.lhs < b.lhs
  end)
  return out
end

function KeyBroker:conflicts()
  return {
    rejected = self.rejected,
    duplicates = self.duplicates,
    shadows = self.shadows,
  }
end

return KeyBroker
