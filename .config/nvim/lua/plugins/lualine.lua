--- Statusline.

local function lsp_clients()
	local names = vim.tbl_map(function(c)
		return c.name
	end, vim.lsp.get_clients({ bufnr = 0 }))
	return #names > 0 and ("󰒋 " .. table.concat(names, ", ")) or ""
end

local function cwd_name()
	return " " .. vim.fn.fnamemodify(vim.uv.cwd() or "", ":t")
end

local function cursor_position()
	return (" %d:%d"):format(vim.fn.line("."), vim.fn.virtcol("."))
end

return {
	"nvim-lualine/lualine.nvim",
	lazy = false,
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			component_separators = "",
			section_separators = "",
			globalstatus = true,
		},
		sections = {
			lualine_a = {
				{
					"mode",
					fmt = function(s)
						return " " .. s
					end,
				},
			},
			lualine_b = {
				{ "filename", symbols = { modified = " ●", readonly = " 󰌾", unnamed = "[No Name]" } },
				{ "branch", icon = "" },
				{ "diff", symbols = { added = " ", modified = " ", removed = " " } },
			},
			lualine_c = {},
			lualine_x = {
				{ "diagnostics", symbols = { error = " ", warn = " ", info = " ", hint = " " } },
				{ lsp_clients, color = { gui = "bold" } },
				{ cwd_name },
			},
			lualine_y = { "filetype" },
			lualine_z = { cursor_position },
		},
	},
}
