local opt = vim.opt

-- Interface
opt.number = true
opt.relativenumber = true           
opt.cursorline = true
opt.termguicolors = true
opt.signcolumn = "yes"
opt.wrap = true
opt.scrolloff = 10
opt.sidescrolloff = 8
opt.shortmess:append("I")

-- Indentation
opt.expandtab = true
opt.shiftwidth = 2
opt.softtabstop = 2
opt.tabstop = 2
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true
opt.inccommand = "split"

-- Visual settings
opt.termguicolors = true
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.matchtime = 2
opt.cmdheight = 1
opt.showmode = false
opt.pumheight = 10
opt.pumblend = 10
opt.winblend = 0
opt.concealcursor = ""
opt.lazyredraw = true
opt.synmaxcol = 300
opt.laststatus = 3
opt.winborder = "single"
opt.showmatch = true
opt.completeopt = { "menu", "menuone", "noselect", "fuzzy", "popup" }

-- Splits
opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

-- File handling
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.autoread = true
opt.autowrite = true
opt.confirm = true
opt.updatetime = 300
opt.timeoutlen = 500
opt.timeoutlen = 0

-- Behaivor settings
opt.hidden = true
opt.errorbells = false
opt.backspace = "indent,eol,start"
opt.autochdir = false
opt.iskeyword:append("-")                      -- Treat dash as part of word
opt.selection = "exclusive"                    -- Selection behavior
opt.modifiable = true                          -- Allow buffer modifications
opt.encoding = "UTF-8"                         -- Set encoding
opt.clipboard = "unnamedplus"
opt.mouse = "a"

-- Cursor settings
vim.opt.guicursor = {
  "n-v-c:block",      -- Normal, Visual, Comandos: Bloque sólido. (Estabilidad, sin parpadear)
  "i-ci-ve:ver25",    -- Insertar: Barra vertical del 25% de grosor. (Estilo moderno como VSCode)
  "r-cr:hor20",       -- Reemplazar: Subrayado del 20% de grosor. (Indica que vas a sobreescribir)
  "o:hor50",          -- Operador pendiente: Medio bloque. (Aparece cuando presionas 'd' o 'y' y Neovim espera un movimiento)
  "a:blinkwait700-blinkoff400-blinkon250", -- Parpadeo suave y moderno para todos los modos
}

-- Folding 
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false
opt.foldlevel = 99

-- Split behavior
opt.splitbelow = true
opt.splitright = true


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
  virtual_lines = false,
  underline = false,
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
