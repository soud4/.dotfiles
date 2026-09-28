return {
  {
    -- =========================================================================
    -- PLUGIN: nvim-treesitter
    -- Motor de análisis sintáctico basado en Árboles de Sintaxis Abstracta (AST).
    -- Proporciona resaltado de sintaxis ultra preciso, indentación inteligente
    -- y selección incremental de bloques de código.
    -- =========================================================================
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate", -- Actualiza automáticamente los parsers al actualizar el plugin
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      -- Objetos de texto y navegación por estructura del código (funciones, clases,
      -- parámetros). Es lo que en un IDE haría el árbol de símbolos, pero sin panel.
      -- branch master para que case con la de nvim-treesitter.
      { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
    },
    config = function()
      -- Fix compatibilidad Neovim 0.12+ con directivas heredadas de nvim-treesitter (master)
      local query = vim.treesitter.query
      local function unwrap_node(node)
        return type(node) == "table" and node[1] or node
      end

      query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
        local capture_id = pred[2]
        local node = unwrap_node(match[capture_id])
        if not node then return end
        local text = vim.treesitter.get_node_text(node, bufnr)
        local alias = text:lower():match("^%s*([%w_%-]+)")
        if not alias then return end
        local match_ft = vim.filetype.match({ filename = "a." .. alias })
        metadata["injection.language"] = match_ft or alias
      end, { force = true, all = true })

      query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
        local id = pred[2]
        local node = unwrap_node(match[id])
        if not node then return end
        local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
        if not metadata[id] then metadata[id] = {} end
        metadata[id]["text"] = text:lower()
      end, { force = true, all = true })

      local ok, configs = pcall(require, "nvim-treesitter.configs")
      if not ok then
        configs = require("nvim-treesitter.config")
      end

      configs.setup({
        -- ---------------------------------------------------------------------
        -- PARSERS / GRAMÁTICAS A INSTALAR AUTOMÁTICAMENTE
        -- ---------------------------------------------------------------------
        ensure_installed = {
          "c",
          "cpp",
          "lua",
          "vim",
          "vimdoc",
          "bash",
          "php",
          "php_only",
          "javascript",
          "typescript",
          "tsx",
          "html",
          "css",
          "scss",
          "json",
          "yaml",
          "markdown",
          "markdown_inline",
          "sql",
          "dockerfile",
          "gitignore",
        },
        auto_install = true, -- Instala automáticamente parsers si abres un archivo nuevo

        -- ---------------------------------------------------------------------
        -- RESALTADO DE SINTAXIS AVANZADO (Highlight)
        -- ---------------------------------------------------------------------
        highlight = {
          enable = true,
          additional_vim_regex_highlighting = false, -- Desactiva regex antiguo para máximo rendimiento
        },

        -- ---------------------------------------------------------------------
        -- INDENTACIÓN INTELIGENTE BASADA EN SINTAXIS
        -- ---------------------------------------------------------------------
        indent = {
          enable = true,
        },

        -- ---------------------------------------------------------------------
        -- SELECCIÓN INCREMENTAL INTELIGENTE
        -- Permite expandir la selección de código por niveles sintácticos:
        -- (Palabra -> Expresión -> Sentencia -> Bloque -> Función -> Archivo)
        -- ---------------------------------------------------------------------
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",   -- Iniciar selección sintáctica
            node_incremental = "<C-space>", -- Expandir al siguiente nodo sintáctico
            scope_incremental = false,
            node_decremental = "<bs>",      -- Reducir selección al nodo anterior (Tecla Retroceso / Backspace)
          },
        },

        -- ---------------------------------------------------------------------
        -- OBJETOS DE TEXTO Y NAVEGACIÓN POR ESTRUCTURA
        -- Operar sobre funciones, clases y parámetros enteros sin seleccionarlos
        -- a mano: daf (borrar función), vac (seleccionar clase), cia (cambiar
        -- parámetro)... y saltar entre ellos con ]f / [f.
        -- ---------------------------------------------------------------------
        textobjects = {
          select = {
            enable = true,
            lookahead = true, -- salta al siguiente objeto si el cursor no está dentro de uno
            keymaps = {
              ["af"] = { query = "@function.outer", desc = "función entera" },
              ["if"] = { query = "@function.inner", desc = "cuerpo de la función" },
              ["ac"] = { query = "@class.outer", desc = "clase entera" },
              ["ic"] = { query = "@class.inner", desc = "cuerpo de la clase" },
              ["aa"] = { query = "@parameter.outer", desc = "parámetro con su coma" },
              ["ia"] = { query = "@parameter.inner", desc = "parámetro" },
              ["ai"] = { query = "@conditional.outer", desc = "condicional entero" },
              ["ii"] = { query = "@conditional.inner", desc = "cuerpo del condicional" },
              ["al"] = { query = "@loop.outer", desc = "bucle entero" },
              ["il"] = { query = "@loop.inner", desc = "cuerpo del bucle" },
            },
          },

          move = {
            enable = true,
            set_jumps = true, -- registra los saltos en la jumplist (<C-o> vuelve atrás)
            goto_next_start = {
              ["]f"] = { query = "@function.outer", desc = "Siguiente función" },
              -- ]C en mayúscula: ]c es el salto de diff nativo de vim, que gitsigns usa
              ["]C"] = { query = "@class.outer", desc = "Siguiente clase" },
              ["]a"] = { query = "@parameter.inner", desc = "Siguiente parámetro" },
            },
            goto_previous_start = {
              ["[f"] = { query = "@function.outer", desc = "Función anterior" },
              ["[C"] = { query = "@class.outer", desc = "Clase anterior" },
              ["[a"] = { query = "@parameter.inner", desc = "Parámetro anterior" },
            },
          },

          swap = {
            enable = true,
            swap_next = {
              ["<leader>sa"] = { query = "@parameter.inner", desc = "Intercambiar con el parámetro siguiente" },
            },
            swap_previous = {
              ["<leader>sA"] = { query = "@parameter.inner", desc = "Intercambiar con el parámetro anterior" },
            },
          },
        },
      })
    end,
  },
}

