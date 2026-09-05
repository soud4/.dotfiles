return {
  -- ===========================================================================
  -- PLUGIN: conform.nvim
  -- Formateador de código ultra rápido y ligero.
  -- Soporta múltiples formateadores por lenguaje y fallback al LSP.
  -- ===========================================================================
  "stevearc/conform.nvim",
  event = { "BufWritePre" }, -- Se carga al guardar un archivo
  cmd = { "ConformInfo" },   -- Comando :ConformInfo para ver el estado de los formateadores
  keys = {
    {
      "<leader>f",
      function()
        -- Formatea el buffer actual o la selección visual
        require("conform").format({
          async = true,        -- Ejecución asíncrona para no congelar la interfaz
          lsp_fallback = true, -- Si no hay formateador externo (ej. prettier), usa el LSP
        })
      end,
      mode = { "n", "v" },
      desc = "Conform: Formatear archivo o selección",
    },
  },
  opts = {
    -- -------------------------------------------------------------------------
    -- ASIGNACIÓN DE FORMATEADORES POR TIPO DE ARCHIVO
    -- stop_after_first = true ejecuta el primer formateador disponible en el sistema.
    -- -------------------------------------------------------------------------
    formatters_by_ft = {
      lua = { "stylua" },
      php = { "pint", "php_cs_fixer", stop_after_first = true },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      c = { "clang-format" },
      cpp = { "clang-format" },
      sh = { "shfmt" },
    },

    -- -------------------------------------------------------------------------
    -- FORMATEO AUTOMÁTICO AL GUARDAR (Descomentar si deseas auto-format al guardar)
    -- -------------------------------------------------------------------------
    -- format_on_save = {
    --   timeout_ms = 500,
    --   lsp_fallback = true,
    -- },
  },
}

