local map = vim.keymap.set

local function notify_state(label, on)
  vim.notify(label .. ": " .. (on and "on" or "off"))
end

local function toggle_wo(name)
  return function()
    vim.wo[name] = not vim.wo[name]
    notify_state(name, vim.wo[name])
  end
end

-- Los gr* por defecto de Neovim harían esperar a `gr` (references) por 'timeoutlen'.
for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
  for _, mode in ipairs({ "n", "x" }) do
    pcall(vim.keymap.del, mode, lhs)
  end
end

-- Diagnostics
map("n", "<leader>dd", vim.diagnostic.open_float, { desc = "Diagnostic under the cursor" })
map("n", "<leader>dl", vim.diagnostic.setqflist, { desc = "List diagnostics" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Previous diagnostic" })

-- Editing
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

-- Native find
map("n", "<leader>Ff", ":find ", { desc = "Find file (:find)" })
map("n", "<leader>Fg", ":silent grep! ", { desc = "Grep project (:grep)" })
map("n", "<leader>Fb", ":buffer ", { desc = "Switch buffer" })

-- Toggles (<leader>tb está en plugins/gitsigns.lua)
map("n", "<leader>tw", toggle_wo("wrap"), { desc = "Toggle: line wrap" })
map("n", "<leader>tn", toggle_wo("relativenumber"), { desc = "Toggle: relative numbers" })
map("n", "<leader>ts", toggle_wo("spell"), { desc = "Toggle: spell check" })

map("n", "<leader>td", function()
  local enabled = not vim.diagnostic.is_enabled()
  vim.diagnostic.enable(enabled)
  notify_state("diagnostics", enabled)
end, { desc = "Toggle: diagnostics" })

map("n", "<leader>th", function()
  local enabled = not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
  vim.lsp.inlay_hint.enable(enabled, { bufnr = 0 })
  notify_state("inlay hints", enabled)
end, { desc = "Toggle: LSP inlay hints" })

map("n", "<leader>tf", function()
  vim.g.format_on_save = not vim.g.format_on_save
  notify_state("format on save", vim.g.format_on_save)
end, { desc = "Toggle: format on save" })

map("n", "<leader>tm", function()
  if package.loaded["render-markdown"] then
    return require("render-markdown").buf_toggle()
  end
  vim.wo.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
  notify_state("conceal", vim.wo.conceallevel ~= 0)
end, { desc = "Toggle: markdown rendering" })
