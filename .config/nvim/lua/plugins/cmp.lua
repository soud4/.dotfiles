--- Completion and snippets.

local icons = {
	Namespace = "󰌗",
	Text = "󰉿",
	Method = "󰆧",
	Function = "󰆧",
	Constructor = "",
	Field = "󰜢",
	Variable = "󰀫",
	Class = "󰠱",
	Interface = "",
	Module = "",
	Property = "󰜢",
	Unit = "󰑭",
	Value = "󰎠",
	Enum = "",
	Keyword = "󰌋",
	Snippet = "",
	Color = "󱓻",
	File = "󰈚",
	Reference = "󰈇",
	Folder = "󰉋",
	EnumMember = "",
	Constant = "󰏿",
	Struct = "󰙅",
	Event = "",
	Operator = "󰆕",
	TypeParameter = "󰊄",
	Table = "",
	Object = "󰅩",
	Tag = "",
	Array = "[]",
	Boolean = "",
	Number = "",
	Null = "󰟢",
	String = "󰉿",
	Package = "",
}

local function format_item(entry, item)
	local kind = item.kind or ""
	item.kind = (" %s "):format(icons[kind] or icons.File)
	item.menu = ("%-9s [%s]"):format(kind, entry.source.name)
	if #item.abbr > 38 then
		item.abbr = item.abbr:sub(1, 38) .. "…"
	end
	return item
end

return {
	"hrsh7th/nvim-cmp",
	event = { "InsertEnter", "CmdlineEnter" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		"hrsh7th/cmp-buffer",
		"hrsh7th/cmp-path",
		"L3MON4D3/LuaSnip",
		"saadparwaiz1/cmp_luasnip",
		"rafamadriz/friendly-snippets",
	},
	config = function()
		local cmp = require("cmp")
		local luasnip = require("luasnip")
		require("luasnip.loaders.from_vscode").lazy_load()

		-- Menú abierto: moverse. Si no, saltar dentro del snippet. Si no, <Tab> normal.
		local function tab(forward)
			return cmp.mapping(function(fallback)
				if cmp.visible() then
					return forward and cmp.select_next_item() or cmp.select_prev_item()
				elseif forward and luasnip.expand_or_jumpable() then
					return luasnip.expand_or_jump()
				elseif not forward and luasnip.jumpable(-1) then
					return luasnip.jump(-1)
				end
				fallback()
			end, { "i", "s" })
		end

		cmp.setup({
			snippet = {
				expand = function(args)
					luasnip.lsp_expand(args.body)
				end,
			},
			window = {
				completion = cmp.config.window.bordered({ border = "single", scrollbar = false }),
				documentation = cmp.config.window.bordered({ border = "single", max_width = 80, max_height = 20 }),
			},
			mapping = cmp.mapping.preset.insert({
				["<C-k>"] = cmp.mapping.select_prev_item(),
				["<C-j>"] = cmp.mapping.select_next_item(),
				["<C-b>"] = cmp.mapping.scroll_docs(-4),
				["<C-f>"] = cmp.mapping.scroll_docs(4),
				["<C-Space>"] = cmp.mapping.complete(),
				["<C-e>"] = cmp.mapping.abort(),
				["<CR>"] = cmp.mapping.confirm({ select = false }),
				["<Tab>"] = tab(true),
				["<S-Tab>"] = tab(false),
			}),
			formatting = {
				fields = { "kind", "abbr", "menu" },
				format = format_item,
			},
			sources = {
				{ name = "nvim_lsp", priority = 1000 },
				{ name = "luasnip", priority = 750 },
				{ name = "path", priority = 500 },
				{ name = "buffer", priority = 250, keyword_length = 2 },
			},
		})
	end,
}
