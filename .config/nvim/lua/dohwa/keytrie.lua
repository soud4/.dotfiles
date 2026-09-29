local Object = require("dohwa.object")

--- A trie of key sequences for one mode.
---
--- Because every mapping in Dohwa is declared as data before anything is set,
--- the whole keymap model can be validated in one pass. The trie is what makes
--- the two interesting problems visible:
---
---   * an exact duplicate  — two modules on the same sequence;
---   * a prefix shadow     — a node that is both terminal and internal, e.g.
---     `<leader>f` mapped while `<leader>ff` also exists. Neovim will sit on
---     the short one until `timeoutlen` expires. That class of bug is invisible
---     in a normal config and is exactly what bit `<leader>f` here.
---@class KeyTrie : Object
---@field mode string
local KeyTrie = Object:extend("KeyTrie")

function KeyTrie:init(mode)
  self.mode = mode
  self.root = { children = {} }
end

--- Split `<leader>ff` into { "<leader>", "f", "f" }.
--- Angle-bracket tokens are lowercased so `<Leader>` and `<leader>` collide.
---@param lhs string
---@return string[]
function KeyTrie.tokenize(lhs)
  local tokens, i, n = {}, 1, #lhs
  while i <= n do
    if lhs:sub(i, i) == "<" then
      local close = lhs:find(">", i + 1, true)
      if close then
        tokens[#tokens + 1] = lhs:sub(i, close):lower()
        i = close + 1
      else
        tokens[#tokens + 1] = lhs:sub(i, i)
        i = i + 1
      end
    else
      tokens[#tokens + 1] = lhs:sub(i, i)
      i = i + 1
    end
  end
  return tokens
end

function KeyTrie:_walk(tokens, create)
  local node = self.root
  for _, token in ipairs(tokens) do
    local child = node.children[token]
    if not child then
      if not create then
        return nil
      end
      child = { children = {} }
      node.children[token] = child
    end
    node = child
  end
  return node
end

---@param prefix string
---@param reservation { owner: string, desc: string }
function KeyTrie:reserve(prefix, reservation)
  local node = self:_walk(KeyTrie.tokenize(prefix), true)
  node.reservation = reservation
  return node
end

--- The innermost reservation covering `lhs`, or nil when the key is unclaimed
--- territory (the global namespace, only core may touch it).
---@param lhs string
---@return table|nil reservation
function KeyTrie:covering_reservation(lhs)
  local node, found = self.root, nil
  for _, token in ipairs(KeyTrie.tokenize(lhs)) do
    node = node.children[token]
    if not node then
      break
    end
    if node.reservation then
      found = node.reservation
    end
  end
  return found
end

---@param lhs string
---@param claim table
function KeyTrie:claim(lhs, claim)
  local node = self:_walk(KeyTrie.tokenize(lhs), true)
  node.claims = node.claims or {}
  node.claims[#node.claims + 1] = claim
  return node
end

--- Validate the whole trie.
---@return table[] duplicates, table[] shadows
function KeyTrie:analyze()
  local duplicates, shadows = {}, {}
  local function visit(node, path)
    local claims = node.claims
    if claims and #claims > 0 then
      if #claims > 1 then
        duplicates[#duplicates + 1] = { mode = self.mode, lhs = path, claims = claims }
      end
      if next(node.children) ~= nil then
        local longer = {}
        local function collect(n, p)
          if n.claims and #n.claims > 0 then
            longer[#longer + 1] = p
          end
          for token, child in pairs(n.children) do
            collect(child, p .. token)
          end
        end
        for token, child in pairs(node.children) do
          collect(child, path .. token)
        end
        if #longer > 0 then
          table.sort(longer)
          shadows[#shadows + 1] = {
            mode = self.mode,
            lhs = path,
            owner = claims[1].owner,
            shadowed = longer,
          }
        end
      end
    end
    for token, child in pairs(node.children) do
      visit(child, path .. token)
    end
  end
  visit(self.root, "")
  table.sort(duplicates, function(a, b)
    return a.lhs < b.lhs
  end)
  table.sort(shadows, function(a, b)
    return a.lhs < b.lhs
  end)
  return duplicates, shadows
end

return KeyTrie
