return {
  {
    -- =========================================================================
    -- PLUGIN: nvim-autopairs
    -- Cierre automático inteligente de paréntesis (), corchetes [], llaves {},
    -- comillas "", '', backticks ``, y tags.
    -- Se integra automáticamente con nvim-cmp para añadir () tras autocompletar funciones.
    -- =========================================================================
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/nvim-cmp", -- Integración directa con el motor de autocompletado
    },
    opts = {
      check_ts = true, -- Utiliza Treesitter para verificar el contexto sintáctico
      ts_config = {
        lua = { "string" }, -- No añade parejas automáticas dentro de strings en Lua
        javascript = { "template_string" }, -- Manejo de template literals en JS
        java = false,
      },
      disable_filetype = { "TelescopePrompt", "spectre_panel", "guihua" },
      fast_wrap = {
        map = "<M-e>", -- Atajo Alt+e para envolver rápidamente una palabra o línea con paréntesis/llaves
        chars = { "{", "[", "(", '"', "'" },
        pattern = [=[[%'%"%>%]%)%}%,]]=],
        end_key = "$",
        keys = "qwertyuiopzxcvbnmasdfghjkl",
        check_comma = true,
        highlight = "Search",
        highlight_grey = "Comment",
      },
    },
    config = function(_, opts)
      local autopairs = require("nvim-autopairs")
      autopairs.setup(opts)

      -- -----------------------------------------------------------------------
      -- INTEGRACIÓN CON NVIM-CMP:
      -- Al presionar Enter sobre una función o método en el menú de sugerencias,
      -- añade automáticamente los paréntesis () y posiciona el cursor dentro.
      -- -----------------------------------------------------------------------
      local cmp_autopairs = require("nvim-autopairs.completion.cmp")
      local cmp = require("cmp")
      cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
    end,
  },
}
