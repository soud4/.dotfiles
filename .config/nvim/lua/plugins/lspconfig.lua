return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		config = function()
			-- Capacidades extendidas con nvim-cmp
			local capabilities = require("cmp_nvim_lsp").default_capabilities()

			-- Keymaps que se activan solo cuando hay un LSP conectado al buffer
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
				callback = function(ev)
					local buf = ev.buf
					local opts = { buffer = buf, silent = true }

					-- Navegación
					vim.keymap.set("n", "gd", vim.lsp.buf.definition,      vim.tbl_extend("force", opts, { desc = "LSP: Go to definition" }))
					vim.keymap.set("n", "gD", vim.lsp.buf.declaration,     vim.tbl_extend("force", opts, { desc = "LSP: Go to declaration" }))
					vim.keymap.set("n", "gr", vim.lsp.buf.references,      vim.tbl_extend("force", opts, { desc = "LSP: Go to references" }))
					vim.keymap.set("n", "gi", vim.lsp.buf.implementation,  vim.tbl_extend("force", opts, { desc = "LSP: Go to implementation" }))
					vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "LSP: Go to type definition" }))

					-- Documentación
					vim.keymap.set("n", "K",          vim.lsp.buf.hover,          vim.tbl_extend("force", opts, { desc = "LSP: Hover documentation" }))
					vim.keymap.set("n", "<C-k>",      vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "LSP: Signature help" }))

					-- Acciones
					vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename,         vim.tbl_extend("force", opts, { desc = "LSP: Rename symbol" }))
					vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP: Code action" }))

					-- Diagnósticos
					vim.keymap.set("n", "<leader>d",  vim.diagnostic.open_float,  vim.tbl_extend("force", opts, { desc = "LSP: Show diagnostics" }))
					vim.keymap.set("n", "[d",         vim.diagnostic.goto_prev,    vim.tbl_extend("force", opts, { desc = "LSP: Previous diagnostic" }))
					vim.keymap.set("n", "]d",         vim.diagnostic.goto_next,    vim.tbl_extend("force", opts, { desc = "LSP: Next diagnostic" }))
				end,
			})

			-- Apariencia de diagnósticos
			vim.diagnostic.config({
				virtual_text = { prefix = "●" },
				signs = true,
				underline = true,
				update_in_insert = false,
				severity_sort = true,
				float = { border = "rounded" },
			})

			-- ─── Configuración de servidores ─────────────────────────────────────────
			-- Para agregar un nuevo servidor, solo añade una entrada aquí.
			-- El loop de abajo aplica vim.lsp.config() + vim.lsp.enable() automáticamente.
			local servers = {
				-- Bash / Shell
				bashls = {
					capabilities = capabilities,
					filetypes = { "sh", "bash", "zsh" },
				},

				-- C / C++
				clangd = {
					capabilities = capabilities,
					cmd = {
						"clangd",
						"--background-index",          -- indexado en background
						"--clang-tidy",                -- linting con clang-tidy
						"--header-insertion=iwyu",     -- include-what-you-use
						"--completion-style=detailed", -- completados detallados
						"--fallback-style=llvm",       -- estilo de formato por defecto
					},
					filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
					root_dir = function(fname)
						local util = require("lspconfig.util")
						return util.root_pattern(
							"compile_commands.json",
							"compile_flags.txt",
							".clangd",
							".git"
						)(fname)
					end,
				},

				-- Lua
				lua_ls = {
					capabilities = capabilities,
					settings = {
						Lua = {
							runtime = { version = "LuaJIT" },
							diagnostics = { globals = { "vim" } },
							workspace = {
								library = vim.api.nvim_get_runtime_file("", true),
								checkThirdParty = false,
							},
							telemetry = { enable = false },
						},
					},
				},
			}

			-- Registra y habilita todos los servidores de la tabla
			for server, config in pairs(servers) do
				vim.lsp.config(server, config)
				vim.lsp.enable(server)
			end
		end,
	},
}
