--- Key hints.
return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	keys = {
		{
			"<leader>??",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Show available keys",
		},
	},
	opts = {
		preset = "helix",
		delay = 500,
		icons = { mappings = false },
		win = { border = "single" },
		spec = {
			{ "<leader>c", group = "Code" },
			{ "<leader>d", group = "Diagnostics" },
			{ "<leader>D", group = "Devcontainer" },
			{ "<leader>f", group = "Find" },
			{ "<leader>F", group = "Native find" },
			{ "<leader>g", group = "Git" },
			{ "<leader>s", group = "Swap (tree-sitter)" },
			{ "<leader>t", group = "Toggles" },
			{ "<leader>=", group = "Format" },
			{ "<leader>?", group = "Key hints" },
			{ "<localleader>l", group = "VimTeX" },
			{ "]", group = "Next" },
			{ "[", group = "Previous" },
		},
	},
}
