--- Formatting.

-- vim.g.format_on_save lo alterna <leader>tf.
local function format_on_save()
	if vim.g.format_on_save then
		return { timeout_ms = 1000, lsp_format = "fallback" }
	end
end

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
			tex = { "latexindent" },
			c = { "clang-format" },
			cpp = { "clang-format" },
			sh = { "shfmt" },
		},
		formatters = {
			-- Sin indent.log en el directorio actual.
			latexindent = { prepend_args = { "-g", "/dev/null" } },
		},
	},
}
