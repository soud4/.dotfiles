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
      })
    end,
  },
}

