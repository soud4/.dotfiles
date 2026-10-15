--- Colour scheme. Loaded eagerly and first: everything else draws on top of it.

-- 1. datos
local opts = {
  terminal_colors = true,
  undercurl = true,
  underline = true,
  bold = true,
  italic = {
    strings = true,
    emphasis = true,
    comments = true,
    operators = false,
    folds = true,
  },
  strikethrough = true,
  invert_selection = false,
  inverse = true,
  contrast = "",
  dim_inactive = false,
  transparent_mode = true,
}

-- 2. el spec
return {
  "ellisonleao/gruvbox.nvim",
  lazy = false,
  priority = 1000,
  -- `config` y no `opts`: ademas del setup hay que aplicar el colorscheme, y
  -- el orden entre las dos cosas importa.
  config = function()
    require("gruvbox").setup(opts)
    vim.cmd.colorscheme("gruvbox")
  end,
}
