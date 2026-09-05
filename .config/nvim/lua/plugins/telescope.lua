return {
  -- ===========================================================================
  -- PLUGIN: telescope.nvim
  -- Buscador difuso (fuzzy finder) altamente extensible e interactivo.
  -- Permite buscar archivos, texto en el proyecto, buffers, historial y más.
  -- ===========================================================================
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Biblioteca de utilidades en Lua requerida por Telescope
    {
      -- Compilador nativo en C para acelerar las búsquedas difusas
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
      cond = function()
        return vim.fn.executable("make") == 1
      end,
    },
    "nvim-tree/nvim-web-devicons", -- Iconos para los archivos en los resultados
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local builtin = require("telescope.builtin")

    telescope.setup({
      -- -----------------------------------------------------------------------
      -- CONFIGURACIÓN POR DEFECTO (Aplica a todos los buscadores)
      -- -----------------------------------------------------------------------
      defaults = {
        prompt_prefix = "   ",    -- Icono del cuadro de búsqueda
        selection_caret = " ❯ ",   -- Icono del elemento seleccionado
        entry_prefix = "   ",
        path_display = { "truncate" }, -- Trunca rutas muy largas para mantener la limpieza
        sorting_strategy = "ascending", -- Muestra los mejores resultados arriba
        layout_config = {
          horizontal = {
            prompt_position = "top",    -- Barra de búsqueda arriba
            preview_width = 0.55,       -- 55% para la previsualización de código
          },
        },
        -- Patrones de carpetas y archivos a ignorar durante las búsquedas
        file_ignore_patterns = {
          "node_modules/",
          "%.git/",
          "vendor/",
          "target/",
          "build/",
          "dist/",
          "%.lock$",
        },
        -- Atajos dentro de la ventana de búsqueda
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous, -- Mover hacia arriba en modo inserción
            ["<C-j>"] = actions.move_selection_next,     -- Mover hacia abajo en modo inserción
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- Enviar a quickfix
            ["<Esc>"] = actions.close,                  -- Cerrar con Esc
          },
        },
      },

      -- -----------------------------------------------------------------------
      -- CONFIGURACIÓN POR BUSCADOR ESPECÍFICO
      -- -----------------------------------------------------------------------
      pickers = {
        find_files = {
          hidden = true,     -- Incluye archivos ocultos (ej. .env, .gitignore)
          no_ignore = false, -- Respeta los archivos ignorados en .gitignore
        },
        buffers = {
          sort_mru = true,              -- Ordena según el uso más reciente
          ignore_current_buffer = true, -- Oculta el archivo actual en el que estás
        },
      },
    })

    -- Cargar extensión fzf en C si está compilada
    pcall(telescope.load_extension, "fzf")

    -- -------------------------------------------------------------------------
    -- ATAJOS DE TECLADO (Keymaps para Telescope)
    -- -------------------------------------------------------------------------
    local map = vim.keymap.set

    -- Búsqueda de archivos y buffers
    map("n", "<leader>ff", builtin.find_files, { desc = "Telescope: Buscar archivos en proyecto" })
    map("n", "<leader>fg", builtin.live_grep, { desc = "Telescope: Buscar texto en proyecto (Grep)" })
    map("n", "<leader>fw", builtin.grep_string, { desc = "Telescope: Buscar palabra bajo el cursor" })
    map("n", "<leader>fb", builtin.buffers, { desc = "Telescope: Listar buffers abiertos" })
    map("n", "<leader>fr", builtin.oldfiles, { desc = "Telescope: Archivos recientes (Historial)" })
    map("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope: Archivos recientes" })
    map("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Telescope: Buscar en el archivo actual" })

    -- Búsqueda en Neovim y LSP
    map("n", "<leader>fh", builtin.help_tags, { desc = "Telescope: Manual de ayuda de Neovim" })
    map("n", "<leader>fd", builtin.diagnostics, { desc = "Telescope: Lista de diagnósticos / errores" })
    map("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Telescope: Símbolos del archivo actual" })
    map("n", "<leader>fc", function()
      -- Abre el buscador directamente en tu carpeta ~/.config/nvim
      builtin.find_files({ cwd = vim.fn.stdpath("config") })
    end, { desc = "Telescope: Buscar en configuración de Neovim" })
  end,
}

