return {
  {
    -- =========================================================================
    -- PLUGIN: gruvbox.nvim
    -- Esquema de colores retro estilo Gruvbox para Neovim.
    -- Configurado con fondos transparentes para un diseño plano y limpio.
    -- =========================================================================
    "ellisonleao/gruvbox.nvim",
    lazy = false,    -- No retrasar la carga para evitar parpadeos visuales al iniciar Neovim
    priority = 1000, -- Máxima prioridad: se carga antes que cualquier otro plugin
    config = function()
      require("gruvbox").setup({
        terminal_colors = true, -- Aplica los colores de la paleta al terminal integrado
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
        invert_signs = false,
        invert_tabline = false,
        invert_intend_guides = false,
        inverse = true, -- Invierte el fondo para búsquedas, diffs, etc.
        contrast = "",  -- Variantes de contraste: "hard", "soft" o "" (medio/por defecto)
        palette_overrides = {},
        dim_inactive = false,
        transparent_mode = true, -- Habilita fondo transparente
      })

      -- Activa el esquema de colores en Neovim
      vim.cmd("colorscheme gruvbox")
    end,
  },
}
