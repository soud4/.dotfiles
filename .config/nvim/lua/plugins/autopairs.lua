--- Automatic pairs.
return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	dependencies = { "hrsh7th/nvim-cmp" },
	config = function()
		require("nvim-autopairs").setup({
			check_ts = true,
			ts_config = { lua = { "string" }, javascript = { "template_string" } },
			map_cr = false, -- <CR> es de nvim-cmp
			fast_wrap = {}, -- <M-e>
		})
		-- Paréntesis después de completar una función.
		require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
	end,
}
