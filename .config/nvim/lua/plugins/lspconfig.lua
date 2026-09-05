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
        },
        automatic_installation = true,
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
          vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, vim.tbl_extend("force", opts, { desc = "LSP: Ver diagnóstico actual" }))
          vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, vim.tbl_extend("force", opts, { desc = "LSP: Diagnóstico anterior" }))
          vim.keymap.set("n", "]d", vim.diagnostic.goto_next, vim.tbl_extend("force", opts, { desc = "LSP: Diagnóstico siguiente" }))
        end,
      })

      -- -----------------------------------------------------------------------
      -- 4. APARIENCIA DE DIAGNÓSTICOS Y VENTANAS FLOTANTES (Cuadradas)
      -- -----------------------------------------------------------------------
      vim.diagnostic.config({
        virtual_text = { prefix = "●" }, -- Texto inline en la misma línea
        signs = true,                    -- Iconos en la columna izquierda
        underline = true,                -- Subrayado de errores
        update_in_insert = false,        -- No molestar con errores mientras escribes
        severity_sort = true,            -- Priorizar errores graves primero
        float = {
          border = "single",             -- Marco cuadrado para la ventana de diagnósticos
          focusable = false,
        },
      })

      -- Configurar bordes cuadrados para las ventanas flotantes nativas de LSP (Hover y Signature)
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover, { border = "single" }
      )
      vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help, { border = "single" }
      )

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

