--- Language servers. nvim-lspconfig trae los defaults (cmd, filetypes, root);
--- acá solo va lo que cambia respecto a ellos.

local vue_plugin =
	vim.fs.joinpath(vim.fn.stdpath("data"), "mason/packages/vue-language-server/node_modules/@vue/typescript-plugin")

local ts_hints = {
	inlayHints = {
		includeInlayParameterNameHints = "literals",
		includeInlayParameterNameHintsWhenArgumentMatchesName = false,
		includeInlayFunctionParameterTypeHints = true,
		includeInlayVariableTypeHints = false,
		includeInlayPropertyDeclarationTypeHints = true,
		includeInlayFunctionLikeReturnTypeHints = true,
		includeInlayEnumMemberValueHints = true,
	},
}

local servers = {
	intelephense = {
		filetypes = { "php", "phtml", "blade" },
		settings = { intelephense = { files = { maxSize = 5000000 } } },
	},
	ts_ls = {
		filetypes = {
			"javascript",
			"javascriptreact",
			"javascript.jsx",
			"typescript",
			"typescriptreact",
			"typescript.tsx",
			"vue",
		},
		init_options = {
			plugins = {
				{
					name = "@vue/typescript-plugin",
					location = vue_plugin,
					languages = { "javascript", "typescript", "vue" },
				},
			},
		},
		settings = { javascript = ts_hints, typescript = ts_hints },
	},
	vue_ls = {},
	tailwindcss = {},
	html = { filetypes = { "html", "php", "blade", "templ" } },
	cssls = {},
	emmet_language_server = {
		filetypes = { "css", "html", "javascriptreact", "typescriptreact", "php", "blade" },
	},
	clangd = {
		cmd = {
			"clangd",
			"--background-index",
			"--clang-tidy",
			"--header-insertion=iwyu",
			"--completion-style=detailed",
			"--fallback-style=llvm",
		},
	},
	lua_ls = {
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" } },
				hint = { enable = true },
				workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
				telemetry = { enable = false },
			},
		},
	},
	bashls = { filetypes = { "sh", "bash", "zsh" } },
	pyright = {},
	texlab = {}, -- solo LSP; compila VimTeX
}

local function on_attach(event)
	local client = vim.lsp.get_client_by_id(event.data.client_id)
	if not client then
		return
	end
	local buf = event.buf

	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
	end
	local function picker(name)
		return function()
			require("telescope.builtin")[name]()
		end
	end

	map("n", "gd", picker("lsp_definitions"), "Go to definition")
	map("n", "gr", picker("lsp_references"), "Find references")
	map("n", "gi", picker("lsp_implementations"), "Go to implementation")
	map("n", "gt", picker("lsp_type_definitions"), "Go to type definition")
	map("n", "gO", picker("lsp_document_symbols"), "Document symbols")
	map("n", "<leader>cs", picker("lsp_document_symbols"), "Document symbols")
	map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
	map("n", "K", vim.lsp.buf.hover, "Hover documentation")
	map("i", "<C-s>", vim.lsp.buf.signature_help, "Signature help")
	map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
	map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")

	-- En .vue ts_ls (con el plugin de Vue) ya da los hints. Si vue_ls también los
	-- sirve, las dos listas se desincronizan y Neovim tira "Invalid 'col': out of range".
	if client.name == "vue_ls" then
		client.server_capabilities.inlayHintProvider = false
	elseif client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = buf })
	end

	if client:supports_method("textDocument/documentHighlight") then
		local group = vim.api.nvim_create_augroup("config.lsp.highlight." .. buf, { clear = true })
		vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
			buffer = buf,
			group = group,
			callback = vim.lsp.buf.document_highlight,
		})
		vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "LspDetach" }, {
			buffer = buf,
			group = group,
			callback = vim.lsp.buf.clear_references,
		})
	end
end

return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "hrsh7th/cmp-nvim-lsp" },
		config = function()
			vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })
			for name, config in pairs(servers) do
				vim.lsp.config(name, config)
			end
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("config.lsp.attach", { clear = true }),
				callback = on_attach,
			})
			vim.lsp.enable(vim.tbl_keys(servers))
		end,
	},

	-- Solo instalador; carga con :Mason. En una máquina nueva:
	-- :MasonInstall intelephense typescript-language-server vue-language-server
	--   tailwindcss-language-server html-lsp css-lsp emmet-language-server clangd
	--   lua-language-server bash-language-server pyright prettierd tree-sitter-cli texlab
	{
		"williamboman/mason.nvim",
		cmd = { "Mason", "MasonInstall", "MasonUpdate", "MasonUninstall", "MasonLog" },
		opts = {
			PATH = "skip", -- init.lua ya pone mason/bin en el PATH
			ui = {
				border = "single",
				icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
			},
		},
	},
}
