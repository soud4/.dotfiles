--- Keymap audit: find prefix shadows.
---
--- A *prefix shadow* is a mapping that is both a complete sequence and the
--- prefix of another one, e.g. `<leader>f` mapped while `<leader>ff` exists.
--- Neovim sits on the short one until 'timeoutlen' expires, so the editor just
--- feels slow. Nothing reports it, which is why it is worth a command.
---
--- This reads `nvim_get_keymap()` *after* everything is applied, so it sees
--- mappings this config sets, mappings plugins install themselves, and
--- Neovim's own defaults alike. Comparison is on raw bytes, because raw bytes
--- are what Neovim actually matches typeahead against: `<Space>ff`, `<leader>ff`
--- and ` ff` are one and the same sequence.
local M = {}

local MODES = { "n", "i", "v", "x", "o", "s" }

---@return string raw byte sequence Neovim matches against
local function raw(lhs)
  return vim.api.nvim_replace_termcodes(lhs, true, true, true)
end

---@return { shadows: table[], duplicates: table[] }
function M.audit()
  local shadows, duplicates = {}, {}

  for _, mode in ipairs(MODES) do
    local seen = {}
    local entries = {}
    for _, m in ipairs(vim.api.nvim_get_keymap(mode)) do
      local key = raw(m.lhs)
      if seen[key] then
        duplicates[#duplicates + 1] = { mode = mode, lhs = m.lhs, desc = m.desc }
      else
        seen[key] = true
        entries[#entries + 1] = { key = key, lhs = m.lhs, desc = m.desc }
      end
    end

    -- A shadow is an entry that is a strict prefix of another entry.
    for _, a in ipairs(entries) do
      for _, b in ipairs(entries) do
        if #b.key > #a.key and b.key:sub(1, #a.key) == a.key then
          shadows[#shadows + 1] = {
            mode = mode,
            lhs = a.lhs,
            desc = a.desc,
            shadowed_by = b.lhs,
          }
          break
        end
      end
    end
  end

  return { shadows = shadows, duplicates = duplicates }
end

---@return string[]
function M.report()
  local result = M.audit()
  local lines = {}

  if #result.shadows == 0 then
    lines[#lines + 1] = "no prefix shadows"
  else
    lines[#lines + 1] = ("%d prefix shadow(s) — these wait for 'timeoutlen' (%dms)")
      :format(#result.shadows, vim.o.timeoutlen)
    for _, s in ipairs(result.shadows) do
      lines[#lines + 1] = ("  %-3s %-18s shadowed by %-18s %s")
        :format(s.mode, s.lhs, s.shadowed_by, s.desc or "")
    end
  end

  if #result.duplicates > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("%d duplicate mapping(s) — the later one won"):format(#result.duplicates)
    for _, d in ipairs(result.duplicates) do
      lines[#lines + 1] = ("  %-3s %-18s %s"):format(d.mode, d.lhs, d.desc or "")
    end
  end

  return lines
end

function M.setup()
  vim.api.nvim_create_user_command("KeyAudit", function()
    local lines = M.report()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    local width = 0
    for _, line in ipairs(lines) do
      width = math.max(width, vim.fn.strdisplaywidth(line))
    end
    vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = math.min(width + 2, vim.o.columns - 4),
      height = math.min(#lines, vim.o.lines - 6),
      row = 2,
      col = math.floor((vim.o.columns - math.min(width + 2, vim.o.columns - 4)) / 2),
      style = "minimal",
      border = "single",
      title = " keys ",
    })
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = buf, nowait = true })
  end, { desc = "Report prefix shadows and duplicate mappings" })
end

return M
