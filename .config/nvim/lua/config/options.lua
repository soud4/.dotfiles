--- Editor options. Pure Neovim, no plugin knowledge.

local opt = vim.opt

-- Interface
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.wrap = false

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
opt.inccommand = "split" -- live preview of :%s/a/b/g

-- Splits
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen" -- text does not jump when a split opens or closes

-- Files and history
opt.undofile = true
opt.autoread = true -- works together with the :checktime autocommand
opt.confirm = true

-- Responsiveness
opt.updatetime = 250
opt.timeoutlen = 400
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.mouse = "a"
opt.clipboard = "unnamedplus"

-- Appearance
opt.showmode = false -- the statusline shows it
opt.cmdheight = 0
opt.laststatus = 3 -- one global statusline
opt.winborder = "single" -- the default border for floats Neovim itself opens

-- Folding. vim.treesitter.foldexpr() is native in 0.12 and returns 0 for
-- filetypes with no parser, so this is safe before any parser is installed.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false
opt.foldlevel = 99

-- Completion behaviour. nvim-cmp builds on this; it is also what <C-n> and
-- <C-x><C-o> use on their own.
opt.completeopt = { "menu", "menuone", "noselect", "fuzzy", "popup" }

-- Native file navigation: `:find **/name` with a proper completion menu.
-- Kept because :find and :grep remain useful next to Telescope, not instead
-- of it.
opt.path:append("**")
opt.wildmenu = true
opt.wildoptions = "pum"
opt.wildignore:append({
  "*/node_modules/*", "*/.git/*", "*/vendor/*", "*/dist/*", "*/build/*",
})

-- Prefer ripgrep for :grep when it exists; the quickfix list is the native
-- equivalent of a project-wide search.
if vim.fn.executable("rg") == 1 then
  vim.o.grepprg = "rg --vimgrep --smart-case"
  vim.o.grepformat = "%f:%l:%c:%m"
end

-- Diagnostics presentation. Here rather than in the LSP spec: it is a display
-- decision, and it should hold whether or not a server is attached.
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

-- Format on save, read by conform and by the <leader>tf toggle. Genuinely
-- global: both the toggle and the formatter must agree on one switch.
if vim.g.format_on_save == nil then
  vim.g.format_on_save = true
end
