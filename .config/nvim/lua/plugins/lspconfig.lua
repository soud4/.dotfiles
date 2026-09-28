return {
  {
    -- =========================================================================
    -- PLUGIN: nvim-lspconfig + Mason
    -- Configuración del protocolo Language Server Protocol (LSP) nativo de Neovim.
    -- Proporciona autocompletado inteligente, ir a definición, diagnósticos,
    -- renombrado de variables y refactorización.
    -- =========================================================================
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",           -- Envía capacidades de autocompletado al LSP
      "williamboman/mason.nvim",         -- Gestor de paquetes para descargar LSPs, linters y formateadores
      "williamboman/mason-lspconfig.nvim", -- Conecta Mason con nvim-lspconfig
    },
    config = function()
      -- -----------------------------------------------------------------------
      -- 1. CONFIGURACIÓN DE MASON (Interfaz y descarga de servidores)
      -- -----------------------------------------------------------------------
      require("mason").setup({
        ui = {
          border = "single", -- Marco 100% cuadrado a juego con la estética
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })

      -- Servidores que Mason instalará automáticamente si no están presentes
      require("mason-lspconfig").setup({
        ensure_installed = {
          "intelephense",          -- PHP
          "ts_ls",                 -- TypeScript / JavaScript
          "tailwindcss",           -- Tailwind CSS
          "html",                  -- HTML
          "cssls",                 -- CSS / SCSS / LESS
          "clangd",                -- C / C++
          "lua_ls",                -- Lua
          "bashls",                -- Bash / Shell Scripts
          "emmet_language_server", -- Expansión Emmet para HTML / PHP / JSX
          "pyright",               -- Python
        },
        -- Desactivado a propósito: el bucle del final de este archivo ya hace
        -- vim.lsp.config() + vim.lsp.enable() con filetypes propios por servidor.
        -- (En mason-lspconfig v2 la opción es 'automatic_enable', no 'automatic_installation'.)
        automatic_enable = false,
      })

      -- -----------------------------------------------------------------------
      -- 2. CAPACIDADES DEL LSP (Habilita soporte avanzado con nvim-cmp)
      -- -----------------------------------------------------------------------
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- -----------------------------------------------------------------------
      -- 3. ATAJOS DE TECLADO (Se activan solo cuando un LSP se conecta al buffer)
      -- -----------------------------------------------------------------------
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspKeymaps", { clear = true }),
        callback = function(ev)
          local buf = ev.buf
          local opts = { buffer = buf, silent = true }

          -- Si Telescope está instalado, usa sus menús flotantes interactivos
          local has_telescope, tb = pcall(require, "telescope.builtin")
          if has_telescope then
            vim.keymap.set("n", "gd", tb.lsp_definitions, vim.tbl_extend("force", opts, { desc = "LSP: Ir a definición" }))
            vim.keymap.set("n", "gr", tb.lsp_references, vim.tbl_extend("force", opts, { desc = "LSP: Buscar referencias" }))
            vim.keymap.set("n", "gi", tb.lsp_implementations, vim.tbl_extend("force", opts, { desc = "LSP: Ir a implementación" }))
            vim.keymap.set("n", "gt", tb.lsp_type_definitions, vim.tbl_extend("force", opts, { desc = "LSP: Definición de tipo" }))
          else
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "LSP: Ir a definición" }))
            vim.keymap.set("n", "gr", vim.lsp.buf.references, vim.tbl_extend("force", opts, { desc = "LSP: Buscar referencias" }))
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, vim.tbl_extend("force", opts, { desc = "LSP: Ir a implementación" }))
            vim.keymap.set("n", "gt", vim.lsp.buf.type_definition, vim.tbl_extend("force", opts, { desc = "LSP: Definición de tipo" }))
          end

          -- Declaración y documentación flotante
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, vim.tbl_extend("force", opts, { desc = "LSP: Ir a declaración" }))
          vim.keymap.set("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "LSP: Documentación flotante (Hover)" }))
          vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, vim.tbl_extend("force", opts, { desc = "LSP: Ayuda de firma" }))

          -- Acciones y refactorización
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP: Renombrar símbolo" }))
          vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "LSP: Acciones de código" }))

          -- Navegación de errores y diagnósticos
          -- (vim.diagnostic.jump reemplaza a goto_prev/goto_next, deprecados desde nvim 0.11)
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "LSP: Ver diagnóstico actual" }))
          vim.keymap.set("n", "[d", function()
            vim.diagnostic.jump({ count = -1, float = true })
          end, vim.tbl_extend("force", opts, { desc = "LSP: Diagnóstico anterior" }))
          vim.keymap.set("n", "]d", function()
            vim.diagnostic.jump({ count = 1, float = true })
          end, vim.tbl_extend("force", opts, { desc = "LSP: Diagnóstico siguiente" }))

          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if not client then
            return
          end

          -- -------------------------------------------------------------------
          -- INLAY HINTS: tipos inferidos y nombres de parámetros en gris.
          -- Se apagan con <leader>th (ver core/keymaps.lua).
          -- -------------------------------------------------------------------
          if client:supports_method("textDocument/inlayHint") then
            vim.lsp.inlay_hint.enable(true, { bufnr = buf })
          end

          -- -------------------------------------------------------------------
          -- DOCUMENT HIGHLIGHT: resalta las demás ocurrencias del símbolo bajo
          -- el cursor al detenerse. Sin ventanas ni paneles, sólo resaltado.
          -- -------------------------------------------------------------------
          if client:supports_method("textDocument/documentHighlight") then
            local grupo = vim.api.nvim_create_augroup("UserLspHighlight" .. buf, { clear = true })
            vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
              buffer = buf,
              group = grupo,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
              buffer = buf,
              group = grupo,
              callback = vim.lsp.buf.clear_references,
            })
            -- Limpiar el grupo al desconectarse el servidor para no dejar autocmds huérfanos
            vim.api.nvim_create_autocmd("LspDetach", {
              buffer = buf,
              once = true,
              callback = function()
                pcall(vim.api.nvim_del_augroup_by_name, "UserLspHighlight" .. buf)
              end,
            })
          end
        end,
      })

      -- -----------------------------------------------------------------------
      -- 4. APARIENCIA DE DIAGNÓSTICOS
      -- Los bordes de las flotantes los da 'winborder' en core/options.lua,
      -- que sustituye a los vim.lsp.handlers + vim.lsp.with() ya deprecados.
      -- -----------------------------------------------------------------------
      vim.diagnostic.config({
        -- En vez de ensuciar cada línea con texto a la derecha, el mensaje se
        -- despliega debajo sólo en la línea del cursor y desaparece al moverse.
        virtual_text = false,
        virtual_lines = { current_line = true },
        underline = true,         -- Subrayado de errores
        update_in_insert = false, -- No molestar con errores mientras escribes
        severity_sort = true,     -- Priorizar errores graves primero
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ", -- mismos iconos que usa lualine
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.INFO] = " ",
            [vim.diagnostic.severity.HINT] = " ",
          },
        },
        float = {
          focusable = false,
        },
      })

      -- -----------------------------------------------------------------------
      -- 5. CONFIGURACIÓN INDIVIDUAL DE CADA SERVIDOR LSP
      -- -----------------------------------------------------------------------
      local servers = {
        -- PHP (Intelephense)
        intelephense = {
          capabilities = capabilities,
          filetypes = { "php", "phtml", "blade" },
          settings = {
            intelephense = {
              files = { maxSize = 5000000 },
            },
          },
        },

        -- TypeScript / JavaScript (ts_ls)
        ts_ls = {
          capabilities = capabilities,
          filetypes = {
            "javascript",
            "javascriptreact",
            "javascript.jsx",
            "typescript",
            "typescriptreact",
            "typescript.tsx",
          },
          settings = {
            -- Inlay hints: tipos inferidos y nombres de parámetros (se ven en gris).
            -- ts_ls los pide por separado para JS y para TS.
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "literals",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "literals",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },

        -- Tailwind CSS
        tailwindcss = {
          capabilities = capabilities,
          filetypes = {
            "html",
            "css",
            "scss",
            "javascript",
            "javascriptreact",
            "typescript",
            "typescriptreact",
            "php",
            "blade",
            "vue",
            "svelte",
          },
        },

        -- HTML
        html = {
          capabilities = capabilities,
          filetypes = { "html", "php", "blade", "templ" },
        },

        -- CSS / SCSS
        cssls = {
          capabilities = capabilities,
          filetypes = { "css", "scss", "less" },
        },

        -- Emmet (expansión de abreviaciones HTML/CSS en React, PHP, etc.)
        emmet_language_server = {
          capabilities = capabilities,
          filetypes = {
            "css",
            "html",
            "javascriptreact",
            "typescriptreact",
            "php",
            "blade",
          },
        },

        -- C / C++ (Clangd)
        clangd = {
          capabilities = capabilities,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--fallback-style=llvm",
          },
        },

        -- Lua (Configuración especial para Neovim y su API)
        lua_ls = {
          capabilities = capabilities,
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = {
                globals = { "vim" }, -- Evita advertencias sobre la variable global 'vim'
              },
              hint = { enable = true }, -- Inlay hints: tipos y nombres de parámetros

              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
            },
          },
        },

        -- Bash / Shell Scripts
        bashls = {
          capabilities = capabilities,
          filetypes = { "sh", "bash", "zsh" },
        },

        -- Python (Pyright)
        pyright = {
          capabilities = capabilities,
          filetypes = { "python" },
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
      }

      -- -----------------------------------------------------------------------
      -- 6. INICIALIZACIÓN DE SERVIDORES
      -- -----------------------------------------------------------------------
      for server, config in pairs(servers) do
        -- Compatibilidad con API moderna (Neovim >= 0.11) y lspconfig clásico
        if vim.lsp.config then
          vim.lsp.config(server, config)
          vim.lsp.enable(server)
        else
          require("lspconfig")[server].setup(config)
        end
      end
    end,
  },
}

