return {
  {
    -- =========================================================================
    -- PLUGIN: gitsigns.nvim
    -- Señal de git PASIVA, no una interfaz de git: marcas en la columna
    -- izquierda de qué líneas cambiaron, saltos entre hunks y diffs bajo
    -- demanda en ventana flotante. El trabajo de git (commit, push, rebase)
    -- se sigue haciendo desde la terminal.
    -- También alimenta el componente 'diff' de lualine, que sin una fuente
    -- como esta nunca mostraba nada.
    -- =========================================================================
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Signos finos: ocupan la columna que 'signcolumn = "yes"' ya reserva,
      -- así que no desplazan el texto ni añaden ancho a la pantalla.
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "┆" },
      },
      signs_staged_enable = true,
      current_line_blame = false, -- apagado: el blame permanente es ruido visual (toggle en <leader>tB)
      current_line_blame_opts = {
        virt_text_pos = "eol",
        delay = 300,
      },
      preview_config = {
        border = "single", -- a juego con el resto de flotantes
      },

      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(modo, tecla, accion, desc)
          vim.keymap.set(modo, tecla, accion, { buffer = bufnr, silent = true, desc = desc })
        end

        -- Navegación entre hunks (respeta diffs si estás en modo diff)
        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Git: Hunk siguiente")

        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Git: Hunk anterior")

        -- Inspección bajo demanda (todo en flotantes, nada permanente)
        map("n", "<leader>hp", gs.preview_hunk, "Git: Previsualizar hunk")
        map("n", "<leader>hb", function()
          gs.blame_line({ full = true })
        end, "Git: Blame de la línea")
        map("n", "<leader>hd", gs.diffthis, "Git: Diff del archivo")

        -- Deshacer cambios locales
        map("n", "<leader>hr", gs.reset_hunk, "Git: Descartar hunk")
        map("v", "<leader>hr", function()
          gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
        end, "Git: Descartar selección")
        map("n", "<leader>hR", gs.reset_buffer, "Git: Descartar archivo entero")

        -- Objeto de texto: 'ih' selecciona el hunk bajo el cursor
        map({ "o", "x" }, "ih", gs.select_hunk, "Git: Hunk como objeto de texto")
      end,
    },
  },
}
