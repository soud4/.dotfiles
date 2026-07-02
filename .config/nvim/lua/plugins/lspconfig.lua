return {
	{
		"neovim/nvim-lspconfig",
		config = function()
			vim.lsp.config("bashls", {})

			vim.lsp.config("lua_ls", {
				settings = {
					Lua = {
						runtime = { version = "LuaJIT" },
						diagnostics = {
							globals = { "vim" }, -- reconoce `vim` como global
						},
						workspace = {
							library = vim.api.nvim_get_runtime_file("", true),
							checkThirdParty = false,
						},
					},
				},
			})
            vim.lsp.config("clangd", {})
            vim.lsp.enable("clangd")
		end,
	},
}
