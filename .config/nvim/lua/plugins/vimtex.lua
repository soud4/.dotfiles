--- LaTeX: compilación continua con latexmk y vista en zathura (SyncTeX).
--- \ll compilar, \lv ir al PDF, Ctrl+click en zathura vuelve a nvim.
return {
  "lervag/vimtex",
  lazy = false, -- VimTeX no debe cargarse lazy
  init = function()
    vim.g.vimtex_view_method = "zathura_simple" -- Wayland: sin xdotool
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_quickfix_open_on_warning = 0
  end,
}
