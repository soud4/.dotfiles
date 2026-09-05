return {
  {
    -- =========================================================================
    -- PLUGIN: neovim-ayu
    -- Esquema de colores moderno, elegante y de alto contraste.
    -- Configurado con fondos transparentes para un diseño plano y limpio.
    -- =========================================================================
    "Shatur/neovim-ayu",
    lazy = false,    -- No retrasar la carga para evitar parpadeos visuales al iniciar Neovim
    priority = 1000, -- Máxima prioridad: se carga antes que cualquier otro plugin
    config = function()
      require("ayu").setup({
        -- Variantes de ayu:
        -- false = modo oscuro profundo ('dark')
        -- true  = modo oscuro suave ('mirage')
        mirage = false,

        -- Modificaciones manuales a los grupos de resaltado (Highlights):
        -- Establecer bg = "none" permite que Neovim use la transparencia de tu terminal
        overrides = {
          Normal = { bg = "none" },      -- Fondo general de la ventana
          NormalNC = { bg = "none" },    -- Fondo de ventanas no activas
          SignColumn = { bg = "none" },  -- Columna de signos (Git diff, diagnósticos)
          VertSplit = { bg = "none" },   -- Separador vertical entre splits
          EndOfBuffer = { bg = "none" }, -- Oculta los símbolos '~' al final del archivo
          LineNr = { bg = "none" },      -- Columna de números de línea
          FloatBorder = { bg = "none" }, -- Bordes de ventanas flotantes sin fondo sólido
        },
        term_colors = true, -- Aplica los colores de la paleta al terminal integrado
      })

      -- Activa el esquema de colores en Neovim
      vim.cmd("colorscheme ayu")
    end,
  },
}
