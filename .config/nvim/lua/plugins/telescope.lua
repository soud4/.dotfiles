--- Fuzzy finding.
---
--- The keys live here rather than in a central file, which is what makes
--- Telescope load on first use instead of at startup. It used to be the most
--- expensive plugin in the config for exactly that reason.
local u = require("core.utils")
local builtin = u.defer("telescope.builtin")

local icons = {
	prompt = "   ",
	selection = " ❯ ",
	entry = "   ",
}

local keys = {
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
}

function pluginconfig()
	local actions = require("telescope.actions")
	return {
		prompt_prefix = icons.prompt,
		selection_caret = icons.selection,
		entry_prefix = icons.entry,
		path_display = { "truncate" },
		sorting_strategy = "ascending",
		layout_config = {
			horizontal = { prompt_position = "top", preview_width = 0.55 },
		},
		file_ignore_patterns = {
			"node_modules/",
			"%.git/",
			"vendor/",
			"target/",
			"build/",
			"dist/",
			"%.lock$",
		},
		mappings = {
			i = {
				["<C-k>"] = actions.move_selection_previous,
				["<C-j>"] = actions.move_selection_next,
				["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
				["<Esc>"] = actions.close,
			},
		},
		pickers = {
			find_files = { hidden = true, no_ignore = false },
			buffers = { sort_mru = true, ignore_current_buffer = true },
		},
	}
end

local config = function()
	local telescope = require("telescope")
	telescope.setup(pluginconfig())
	pcall(telescope.load_extension, "fzf")
end

return {
	"nvim-telescope/telescope.nvim",
	branch = "0.1.x",
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable("make") == 1
			end,
		},
		"nvim-tree/nvim-web-devicons",
	},

	keys = keys,
	config = config(),
}
