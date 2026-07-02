return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      html = { "prettier" },
      css = { "prettier" },
      json = { "prettier" },
      markdown = { "prettier" },
      php = { "php_cs_fixer" },
      c = { "clang-format" },
      cpp = { "clang-format" },
      java = { "google-java-format" },
      sh = { "shfmt" },
    },
  },

  config = function(_, opts)
    require("conform").setup(opts)

    vim.keymap.set("n", "<leader>f", function()
      require("conform").format({
        async = true,
        lsp_fallback = true,
      })
    end, { desc = "Format file" })
  end,
}
