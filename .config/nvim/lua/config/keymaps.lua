--- Global keys that belong to no plugin.
---
--- Keys that only make sense with a plugin loaded live in that plugin's own
--- `keys = {}` spec, which also makes it load on first use. LSP keys are
--- buffer-local and set from LspAttach in plugins/lspconfig.lua, so `gd` and `K`
--- keep their built-in meaning in buffers with no server.
local u = require("core.utils")
local map = vim.keymap.set

--------------------------------------------------------------------------
-- Neovim 0.11 ships gr-prefixed LSP mappings (grn, gra, grr, gri, grt).
-- This config binds `gr` itself, which would make every one of them wait for
-- 'timeoutlen'. Removing them keeps `gr` instant. This is the prefix shadow
-- that `:KeyAudit` looks for, and the reason it exists.
--------------------------------------------------------------------------
for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
  for _, mode in ipairs({ "n", "x" }) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

-- Diagnostics. Entirely native: nothing here needs a plugin.
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Diagnostic under the cursor" })
map("n", "<leader>dl", function()
  vim.diagnostic.setqflist()
end, { desc = "List diagnostics" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })

-- Plain editing keys.
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

map("n", "<C-d>", "<C-d>zz", { desc = "Half page down, centred" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up, centred" })
map("n", "n", "nzzzv", { desc = "Next match, centred" })
map("n", "N", "Nzzzv", { desc = "Previous match, centred" })

-- Native project navigation, next to Telescope rather than instead of it:
-- `:find` understands 'path' and 'wildignore', which is sometimes what you want.
map("n", "<leader>Ff", ":find ", { desc = "Find file (:find)", silent = false })
map("n", "<leader>Fg", ":silent grep! ", { desc = "Grep project (:grep)", silent = false })
map("n", "<leader>Fb", ":buffer ", { desc = "Switch buffer", silent = false })

--------------------------------------------------------------------------
-- Toggles. All of them in one place; they used to be spread over six modules.
-- <leader>tb (git blame) lives in plugins/gitsigns.lua, with gitsigns.
--------------------------------------------------------------------------
-- Opciones de ventana: el helper hace el flip y el aviso.
map("n", "<leader>tw", u.toggle_wo("wrap"), { desc = "Toggle: line wrap" })
map("n", "<leader>tn", u.toggle_wo("relativenumber"), { desc = "Toggle: relative numbers" })
map("n", "<leader>ts", u.toggle_wo("spell"), { desc = "Toggle: spell check" })

-- Los que no son opciones de ventana: cada uno consulta su estado por su propia
-- API, asi que solo comparten el aviso.
map("n", "<leader>td", function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  u.notify_state("diagnostics", not enabled)
end, { desc = "Toggle: diagnostics" })

map("n", "<leader>th", function()
  local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
  u.notify_state("inlay hints", not enabled)
end, { desc = "Toggle: LSP inlay hints" })

map("n", "<leader>tf", function()
  vim.g.format_on_save = vim.g.format_on_save == false
  u.notify_state("format on save", vim.g.format_on_save)
end, { desc = "Toggle: format on save" })

map("n", "<leader>tm", function()
  -- render-markdown when it is loaded, plain conceal otherwise: the native
  -- half is four lines, so it is cheaper to keep than to require the plugin.
  if package.loaded["render-markdown"] then
    return require("render-markdown").buf_toggle()
  end
  vim.wo.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
  u.notify_state("conceal", vim.wo.conceallevel ~= 0)
end, { desc = "Toggle: markdown rendering" })
