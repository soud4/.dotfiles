local opt = vim.opt

-- Interface
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.wrap = false
opt.shortmess:append("I")

-- Indentation
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.inccommand = "split"

-- Splits
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- Files and history
opt.undofile = true
opt.autoread = true
opt.confirm = true

-- Responsiveness
opt.updatetime = 250
opt.timeoutlen = 400
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- Appearance
opt.showmode = false
opt.cmdheight = 0
opt.laststatus = 3
opt.winborder = "single"

-- Folding (treesitter pone foldexpr por buffer, ver plugins/treesitter.lua)
opt.foldenable = false
opt.foldlevel = 99

opt.completeopt = { "menu", "menuone", "noselect", "fuzzy", "popup" }

-- :find y :grep nativos
opt.path:append("**")
opt.wildoptions = "pum"
opt.wildignore:append({ "*/node_modules/*", "*/.git/*", "*/vendor/*", "*/dist/*", "*/build/*" })
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
  opt.grepformat = "%f:%l:%c:%m"
end

vim.diagnostic.config({
  virtual_text = false,
  virtual_lines = { current_line = true },
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },
  },
  float = { focusable = false },
})

-- Leído por conform y por el toggle <leader>tf.
vim.g.format_on_save = true
