--- Formatting.

-- 1. helpers

--- Driven by the same flag as the <leader>tf toggle; see config/keymaps.lua.
--- Devolver nil desactiva el formateo al guardar para esta pasada.
local function format_on_save()
  if vim.g.format_on_save == false then
    return nil
  end
  return { timeout_ms = 1000, lsp_format = "fallback" }
end

-- 2. el spec
return {
  "stevearc/conform.nvim",
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  keys = {
    {
      "<leader>==",
      function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end,
      mode = { "n", "v" },
      desc = "Format buffer",
    },
  },
  opts = {
    format_on_save = format_on_save,
    -- stop_after_first runs the first formatter present on the system.
    formatters_by_ft = {
      lua = { "stylua" },
      php = { "pint", "php_cs_fixer", stop_after_first = true },
      javascript = { "prettierd", "prettier", stop_after_first = true },
      typescript = { "prettierd", "prettier", stop_after_first = true },
      javascriptreact = { "prettierd", "prettier", stop_after_first = true },
      typescriptreact = { "prettierd", "prettier", stop_after_first = true },
      vue = { "prettierd", "prettier", stop_after_first = true },
      html = { "prettierd", "prettier", stop_after_first = true },
      css = { "prettierd", "prettier", stop_after_first = true },
      scss = { "prettierd", "prettier", stop_after_first = true },
      json = { "prettierd", "prettier", stop_after_first = true },
      markdown = { "prettierd", "prettier", stop_after_first = true },
      c = { "clang-format" },
      cpp = { "clang-format" },
      sh = { "shfmt" },
    },
  },
}
