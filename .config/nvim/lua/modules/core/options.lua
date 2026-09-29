--- Editor options. Pure Neovim, no plugin knowledge, no dependencies.
--- Protected: this is the floor the rest of the config stands on.
return {
  description = "Editor options",

  native = function(ctx)
    ctx:opt({
      -- Interface
      number = true,
      relativenumber = true,
      cursorline = true,
      termguicolors = true,
      signcolumn = "yes",
      wrap = false,

      -- Indentation
      expandtab = true,
      shiftwidth = 4,
      tabstop = 4,
      smartindent = true,

      -- Search
      ignorecase = true,
      smartcase = true,
      hlsearch = true,
      incsearch = true,
      inccommand = "split", -- live preview of :%s/a/b/g

      -- Splits
      splitright = true,
      splitbelow = true,
      splitkeep = "screen", -- text does not jump when a split opens or closes

      -- Files and history
      undofile = true,
      autoread = true, -- works together with the :checktime autocommand
      confirm = true,

      -- Responsiveness
      updatetime = 250,
      timeoutlen = 400,
      scrolloff = 8,
      sidescrolloff = 8,
      mouse = "a",
      clipboard = "unnamedplus",

      -- Appearance
      showmode = false, -- the statusline shows it
      cmdheight = 0,
      laststatus = 3, -- one global statusline
      winborder = ctx.ui.border, -- one border for every float in the config

      -- Folding. vim.treesitter.foldexpr() is native in 0.12 and returns 0 for
      -- filetypes with no parser, so this is safe with editor.syntax disabled.
      foldmethod = "expr",
      foldexpr = "v:lua.vim.treesitter.foldexpr()",
      foldenable = false,
      foldlevel = 99,

      -- Native completion behaviour. editor.complete builds on this; with the
      -- module off, it is what <C-n> and <C-x><C-o> use.
      completeopt = { "menu", "menuone", "noselect", "fuzzy", "popup" },

      -- Native file navigation, the floor under tools.finder: `:find **/name`
      -- with a proper completion menu.
      path = vim.opt.path + "**",
      wildmenu = true,
      wildoptions = "pum",
      wildignore = vim.opt.wildignore + {
        "*/node_modules/*", "*/.git/*", "*/vendor/*", "*/dist/*", "*/build/*",
      },
    })

    -- Prefer ripgrep for :grep when it exists; the quickfix list is the native
    -- equivalent of a project-wide search.
    if vim.fn.executable("rg") == 1 then
      vim.o.grepprg = "rg --vimgrep --smart-case"
      vim.o.grepformat = "%f:%l:%c:%m"
    end

    -- Diagnostics presentation lives here, not in the LSP module: the
    -- appearance should not change when a plugin is switched off.
    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = { current_line = true },
      underline = true,
      update_in_insert = false,
      severity_sort = true,
      signs = { text = ctx.ui.icons.diagnostics },
      float = { focusable = false },
    })
  end,
}
