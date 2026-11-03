--- LSP: servidores, atajos y comportamiento al conectar.
---
--- Estructura del archivo (de arriba a abajo):
---   1. Interruptores   -> activar/desactivar funciones que pueden dar problemas
---   2. Servidores      -> qué lenguajes tienen LSP y qué cambia de sus defaults
---   3. on_attach       -> atajos y funciones que se activan al conectar un LSP a un buffer
---   4. Plugins         -> nvim-lspconfig (conecta todo) y mason (instalador)

-- ============================================================================
-- 1. INTERRUPTORES
-- ============================================================================
-- Para el bug de las letras que desaparecen en tmux: enciende UNO a la vez,
-- reinicia nvim, abre el archivo que falla y mira si vuelve el problema.
local features = {
  inlay_hints = false, -- texto fantasma (tipos, nombres de parámetros) dentro del código
  document_highlight = false, -- resalta otras apariciones de la palabra bajo el cursor
  semantic_tokens = false, -- colores extra que manda el LSP (si es false, solo usa treesitter)
}
-- Los inlay hints se pueden encender/apagar al vuelo con <leader>th (keymaps.lua).

-- ============================================================================
-- 2. SERVIDORES
-- ============================================================================
-- nvim-lspconfig ya trae por defecto el comando, filetypes y raíz de cada
-- servidor. Aquí solo se escribe lo que quieres CAMBIAR. `{}` = usar defaults.

-- Ruta del plugin de TypeScript para Vue (instalado por Mason junto a vue-language-server).
local vue_plugin =
  vim.fs.joinpath(vim.fn.stdpath("data"), "mason/packages/vue-language-server/node_modules/@vue/typescript-plugin")

-- Opciones de inlay hints de ts_ls (solo se ven si features.inlay_hints = true).
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
  -- PHP
  intelephense = {
    filetypes = { "php", "phtml", "blade" },
    settings = { intelephense = { files = { maxSize = 5000000 } } }, -- permite archivos grandes
  },

  -- JavaScript / TypeScript (LSP nativo oficial de TypeScript 7+)
  tsc = {},

  -- Vue (ts_ls con el plugin de Vue da soporte TS dentro de archivos .vue)
  ts_ls = {
    filetypes = { "vue" },
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

  -- Web
  tailwindcss = {
    settings = {
      tailwindCSS = {
        experimental = {
          classRegex = {
            { [[:class="([^"]*)"]] },
            { [[:class='([^']*)']] },
            { [[x-bind:class="([^"]*)"]] },
            { [[x-bind:class='([^']*)']] },
          },
        },
      },
    },
  },
  html = { filetypes = { "html", "php", "blade", "templ" } },
  cssls = {},
  emmet_language_server = {
    filetypes = { "css", "html", "javascriptreact", "typescriptreact", "php", "blade" },
  },

  -- C / C++
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

  -- Lua (para editar esta config)
  lua_ls = {
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } }, -- evita el aviso "undefined global vim"
        hint = { enable = true },
        workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },

  -- Otros
  bashls = { filetypes = { "sh", "bash", "zsh" } },
  pyright = {},
  texlab = {}, -- solo LSP; la compilación la hace VimTeX
}

-- ============================================================================
-- 3. ON_ATTACH (se ejecuta cada vez que un LSP se conecta a un buffer)
-- ============================================================================
local function on_attach(event)
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client then
    return
  end
  local buf = event.buf

  -- Helper para definir atajos solo en este buffer.
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end
  -- Helper para abrir un picker de Telescope (se carga solo cuando se usa).
  local function picker(name)
    return function()
      require("telescope.builtin")[name]()
    end
  end

  -- --- Atajos ---------------------------------------------------------------
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

  -- --- Semantic tokens ------------------------------------------------------
  -- Si está apagado, el color lo pone solo treesitter.
  if not features.semantic_tokens then
    client.server_capabilities.semanticTokensProvider = nil
  end

  -- --- Inlay hints ----------------------------------------------------------
  -- En .vue, ts_ls (con el plugin de Vue) ya da los hints. Si vue_ls también
  -- los sirve, las dos listas se desincronizan y Neovim tira
  -- "Invalid 'col': out of range". Por eso se los quitamos a vue_ls.
  if client.name == "vue_ls" then
    client.server_capabilities.inlayHintProvider = false
  elseif features.inlay_hints and client:supports_method("textDocument/inlayHint") then
    vim.lsp.inlay_hint.enable(true, { bufnr = buf })
  end

  -- --- Resaltado de referencias bajo el cursor -------------------------------
  if features.document_highlight and client:supports_method("textDocument/documentHighlight") then
    local group = vim.api.nvim_create_augroup("config.lsp.highlight." .. buf, { clear = true })
    -- Al quedarse quieto el cursor: resalta las apariciones.
    vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
      buffer = buf,
      group = group,
      callback = vim.lsp.buf.document_highlight,
    })
    -- Al moverse o desconectar el LSP: limpia el resaltado.
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "LspDetach" }, {
      buffer = buf,
      group = group,
      callback = vim.lsp.buf.clear_references,
    })
  end
end

-- ============================================================================
-- 4. PLUGINS
-- ============================================================================
return {
  -- Conecta los servidores de la sección 2 con Neovim.
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "hrsh7th/cmp-nvim-lsp" }, -- para que el autocompletado funcione con LSP
    config = function()
      -- Capacidades para TODOS los servidores (incluye soporte de nvim-cmp).
      vim.lsp.config("*", { capabilities = require("cmp_nvim_lsp").default_capabilities() })

      -- Config específica de cada servidor.
      for name, config in pairs(servers) do
        vim.lsp.config(name, config)
      end

      -- Ejecuta on_attach cuando un servidor se conecta a un buffer.
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("config.lsp.attach", { clear = true }),
        callback = on_attach,
      })

      -- Activa todos los servidores de la lista.
      vim.lsp.enable(vim.tbl_keys(servers))
    end,
  },

  -- Mason: solo instalador de servidores. Se carga al usar :Mason.
  -- En una máquina nueva:
  --   :MasonInstall tsc intelephense typescript-language-server vue-language-server
  --     tailwindcss-language-server html-lsp css-lsp emmet-language-server clangd
  --     lua-language-server bash-language-server pyright prettierd tree-sitter-cli texlab
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
