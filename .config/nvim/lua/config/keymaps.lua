local map = vim.keymap.set

-----------------------------------------------------------------------------
-- Neovim Defaults Overrides
-----------------------------------------------------------------------------
-- Remove default 'gr*' mappings to avoid 'timeoutlen' delays
for _, key in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
  pcall(vim.keymap.del, { "n", "x" }, key)
end

-----------------------------------------------------------------------------
-- General QoL (Quality of Life) & Editing
-----------------------------------------------------------------------------
-- Clear search highlights on <Esc>
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Keep cursor centered when jumping or searching
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down, centered" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up, centered" })
map("n", "n", "nzzzv", { desc = "Next match, centered" })
map("n", "N", "Nzzzv", { desc = "Previous match, centered" })

-- Join lines without moving the cursor to the end
map("n", "J", "mzJ`z", { desc = "Join lines and keep cursor position" })

-- Black hole register: Delete/Paste without overriding your clipboard
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map({ "n", "v" }, "<leader>d", '"_d', { desc = "Delete without yanking" })

-----------------------------------------------------------------------------
-- Visual Mode Enhancements
-----------------------------------------------------------------------------
-- Move selected lines up/down and auto-indent
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

-- Continuous visual indentation
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })

-----------------------------------------------------------------------------
-- Window & Buffer Management
-----------------------------------------------------------------------------
-- Window navigation
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

-- Window splitting
map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split window vertically" })
map("n", "<leader>sh", ":split<CR>", { desc = "Split window horizontally" })

-- Buffer navigation
map("n", "]b", ":bnext<CR>", { desc = "Next buffer" })
map("n", "[b", ":bprevious<CR>", { desc = "Previous buffer" })
map("n", "<leader>bd", ":bdelete<CR>", { desc = "Close current buffer" })

-----------------------------------------------------------------------------
-- Diagnostics & LSP
-----------------------------------------------------------------------------
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Diagnostic under cursor" })
map("n", "<leader>dl", vim.diagnostic.setqflist, { desc = "List diagnostics" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Previous diagnostic" })

-----------------------------------------------------------------------------
-- Configuration Management
-----------------------------------------------------------------------------
map("n", "<leader>rc", ":e $MYVIMRC<CR>", { desc = "Edit config" })
map("n", "<leader>rl", ":so $MYVIMRC<CR>", { desc = "Reload config" })

-----------------------------------------------------------------------------
-- Native Search (Optional fallback)
-----------------------------------------------------------------------------
map("n", "<leader>Ff", ":find ", { desc = "Find file (:find)" })
map("n", "<leader>Fg", ":silent grep! ", { desc = "Grep project (:grep)" })
map("n", "<leader>Fb", ":buffer ", { desc = "Switch buffer" })
