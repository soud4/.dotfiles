return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		config = function()
			require("mason").setup({
				ui = {
					border = "rounded",
					icons = {
						package_installed = "✓",
						package_pending = "➜",
						package_uninstalled = "✗",
					},
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		config = function()
			require("mason-lspconfig").setup({
				-- Servidores que se instalan automáticamente si no están
				ensure_installed = {
					"clangd",        -- C / C++
					"bashls",        -- Bash / Shell
					"lua_ls",        -- Lua
				},
				automatic_installation = true,
			})
		end,
	},
}
