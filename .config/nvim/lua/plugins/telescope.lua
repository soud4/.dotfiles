--- Fuzzy finding. Carga con la primera tecla.

local function builtin(name, opts)
	return function()
		require("telescope.builtin")[name](opts)
	end
end

return {
	"nvim-telescope/telescope.nvim",
	branch = "master",
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
		"nvim-tree/nvim-web-devicons",
	},
	keys = {
		{ "<leader>ff", builtin("find_files"), desc = "Find files in the project" },
		{ "<leader>fg", builtin("live_grep"), desc = "Search text in the project" },
		{ "<leader>fw", builtin("grep_string"), desc = "Search the word under the cursor" },
		{ "<leader>fb", builtin("buffers"), desc = "List open buffers" },
		{ "<leader>fr", builtin("oldfiles"), desc = "Recently opened files" },
		{ "<leader>fh", builtin("help_tags"), desc = "Search the Neovim manual" },
		{ "<leader>fd", builtin("diagnostics"), desc = "List diagnostics" },
		{
			"<leader>fc",
			builtin("find_files", { cwd = vim.fn.stdpath("config") }),
			desc = "Find files in the Neovim config",
		},
		{ "<leader>/", builtin("current_buffer_fuzzy_find"), desc = "Search inside this file" },
	},
	config = function()
		local telescope = require("telescope")
		local actions = require("telescope.actions")
		telescope.setup({
			defaults = {
				prompt_prefix = "   ",
				selection_caret = " ❯ ",
				entry_prefix = "   ",
				path_display = { "truncate" },
				sorting_strategy = "ascending",
				layout_config = { horizontal = { prompt_position = "top", preview_width = 0.55 } },
				file_ignore_patterns = { "node_modules/", "%.git/", "vendor/", "target/", "build/", "dist/", "%.lock$" },
				mappings = {
					i = {
						["<C-k>"] = actions.move_selection_previous,
						["<C-j>"] = actions.move_selection_next,
						["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
						["<Esc>"] = actions.close,
					},
				},
			},
			pickers = {
				find_files = { hidden = true },
				buffers = { sort_mru = true, ignore_current_buffer = true },
			},
		})
		pcall(telescope.load_extension, "fzf")
	end,
}
