return {
  {
    -- =========================================================================
    -- PLUGIN: which-key.nvim
    -- Sólo aparece si te quedas dudando tras pulsar una tecla líder; el resto
    -- del tiempo es completamente invisible. Aprovecha los 'desc' que ya
    -- llevan todos los keymaps de esta configuración.
    -- =========================================================================
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix", -- panel lateral compacto, sin ocupar toda la pantalla
      delay = 500,      -- ms de espera antes de aparecer: no molesta si sabes el atajo
      icons = {
        mappings = false, -- sin iconos por atajo: la lista queda más limpia
      },
      win = {
        border = "single", -- a juego con 'winborder'
      },

      -- Nombres de los grupos de teclas
      spec = {
        { "<leader>f", group = "Buscar (Telescope)" },
        { "<leader>h", group = "Git (hunks)" },
        { "<leader>t", group = "Interruptores" },
        { "<leader>c", group = "Código" },
        { "<leader>r", group = "Refactorizar" },
        { "<leader>s", group = "Intercambiar (Treesitter)" },
        { "g", group = "Ir a" },
        { "[", group = "Anterior" },
        { "]", group = "Siguiente" },
      },
    },
    keys = {
      {
        "<leader>?",
        function()
          require("which-key").show({ global = false })
        end,
        desc = "Atajos disponibles en este buffer",
      },
    },
  },
}
