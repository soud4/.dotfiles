--- Language servers.
---
--- On Neovim 0.12 `vim.lsp.config()` and `vim.lsp.enable()` are native, so
--- nvim-lspconfig is little more than a library of sensible defaults. The
--- native floor here therefore is not a token gesture: it starts the same
--- servers with the same settings, straight from the table below. What the
--- plugins add is Mason's installer and lspconfig's root detection.
---
--- Capabilities come from the `lsp.capabilities` feature rather than from
--- `require("cmp_nvim_lsp")`. That is the one line that used to make the LSP
--- depend on the completion engine.
local M = {}

--- Everything both paths need: how to start each server, for which filetypes,
--- and what marks a project root.
M.servers = {
  intelephense = {
    cmd = { "intelephense", "--stdio" },
    filetypes = { "php", "phtml", "blade" },
    root_markers = { "composer.json", ".git" },
    settings = { intelephense = { files = { maxSize = 5000000 } } },
  },

  ts_ls = {
    cmd = { "typescript-language-server", "--stdio" },
    filetypes = {
      "javascript", "javascriptreact", "javascript.jsx",
      "typescript", "typescriptreact", "typescript.tsx",
      "vue",
    },
    root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
    init_options = {
      plugins = {
        {
          name = "@vue/typescript-plugin",
          location = vim.fs.joinpath(
            vim.fn.stdpath("data"),
            "mason",
            "packages",
            "vue-language-server",
            "node_modules",
            "@vue",
            "typescript-plugin"
          ),
          languages = { "javascript", "typescript", "vue" },
        },
      },
    },
    settings = (function()
      -- ts_ls wants the same inlay-hint block twice, once per language.
      local hints = {
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
      return { javascript = hints, typescript = hints }
    end)(),
  },

  vue_ls = {
    cmd = { "vue-language-server", "--stdio" },
    filetypes = { "vue" },
    root_markers = { "package.json", "vue.config.js", "vite.config.js", "vite.config.ts", ".git" },
  },

  tailwindcss = {
    cmd = { "tailwindcss-language-server", "--stdio" },
    filetypes = {
      "html", "css", "scss", "javascript", "javascriptreact",
      "typescript", "typescriptreact", "php", "blade", "vue", "svelte",
    },
    root_markers = { "tailwind.config.js", "tailwind.config.ts", "package.json", ".git" },
  },

  html = {
    cmd = { "vscode-html-language-server", "--stdio" },
    filetypes = { "html", "php", "blade", "templ" },
    root_markers = { "package.json", ".git" },
    init_options = { provideFormatter = true, embeddedLanguages = { css = true, javascript = true } },
  },

  cssls = {
    cmd = { "vscode-css-language-server", "--stdio" },
    filetypes = { "css", "scss", "less" },
    root_markers = { "package.json", ".git" },
    init_options = { provideFormatter = true },
  },

  emmet_language_server = {
    cmd = { "emmet-language-server", "--stdio" },
    filetypes = { "css", "html", "javascriptreact", "typescriptreact", "php", "blade" },
    root_markers = { ".git" },
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
    filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
    root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
  },

  lua_ls = {
    cmd = { "lua-language-server" },
    filetypes = { "lua" },
    root_markers = { ".luarc.json", ".stylua.toml", ".git" },
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        hint = { enable = true },
        workspace = {
          library = vim.api.nvim_get_runtime_file("", true),
          checkThirdParty = false,
        },
        telemetry = { enable = false },
      },
    },
  },

  bashls = {
    cmd = { "bash-language-server", "start" },
    filetypes = { "sh", "bash", "zsh" },
    root_markers = { ".git" },
  },

  pyright = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    root_markers = { "pyproject.toml", "setup.py", "requirements.txt", ".git" },
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

--- Mason installs into its own bin directory. Putting it on PATH means the
--- native path can still start servers Mason installed earlier, even with the
--- Mason plugin switched off.
local function add_mason_to_path()
  local bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
  if vim.uv.fs_stat(bin) and not vim.env.PATH:find(bin, 1, true) then
    vim.env.PATH = bin .. ":" .. vim.env.PATH
  end
end

--- Which server wins when several of them serve inlay hints for one buffer.
--- Higher goes first; anything unlisted sits in the middle. ts_ls carries the
--- Vue plugin, so it already answers for .vue buffers and vue_ls loses nothing
--- worth keeping.
local hint_priority = {
  ts_ls = 90,
  clangd = 90,
  lua_ls = 90,
  pyright = 90,
  vue_ls = 10,
}

--- The client whose inlay hints this buffer draws, or nil when none serves them.
local function hint_owner(bufnr)
  local best, best_rank
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/inlayHint" })) do
    local rank = hint_priority[client.name] or 50
    if not best_rank or rank > best_rank or (rank == best_rank and client.id < best.id) then
      best, best_rank = client, rank
    end
  end
  return best
end

--- Neovim keeps one hint list per client but a single `version` for the whole
--- buffer, and a change notification only refreshes the client that sent it
--- (`vim/lsp/inlay_hint.lua`). So with two hint-serving servers on one buffer
--- the fresher answer marks the state current while the other client's byte
--- columns still point into lines that have since shrunk, and the decoration
--- provider dies with "Invalid 'col': out of range". Dropping every answer but
--- the owner's keeps hints and version in step, which is what that code assumes.
local guarded = false
local function guard_inlay_hints()
  if guarded then
    return
  end
  guarded = true

  local upstream = vim.lsp.inlay_hint.on_inlayhint
  vim.lsp.inlay_hint.on_inlayhint = function(err, result, ctx)
    local bufnr = ctx and ctx.bufnr
    if not err and bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
      local owner = hint_owner(bufnr)
      if owner and owner.id ~= ctx.client_id then
        return
      end
    end
    return upstream(err, result, ctx)
  end
end

--- Register and enable servers with the native API.
---@param ctx Context
---@param only_available boolean start only what is actually installed
function M.register(ctx, only_available)
  add_mason_to_path()
  local capabilities = ctx:value("lsp.capabilities", vim.lsp.protocol.make_client_capabilities())
  local started = {}
  for name, config in pairs(M.servers) do
    if not only_available or vim.fn.executable(config.cmd[1]) == 1 then
      vim.lsp.config(name, vim.tbl_extend("force", config, { capabilities = capabilities }))
      vim.lsp.enable(name)
      started[#started + 1] = name
    end
  end
  return started
end

M.description = "Language servers"
M.optional = { "editor.complete", "tools.finder" }

M.native = function(ctx)
  guard_inlay_hints()

  ctx:reserve("<leader>c", "Code")
  ctx:slot({ "n", "v" }, "<leader>ca", "code.action")
  ctx:slot("n", "<leader>cr", "code.rename")
  ctx:slot("n", "<leader>cs", "symbols.document")

  -- Declared here, by the consumer: with editor.complete switched off the
  -- feature still exists and still resolves, to Neovim's own capabilities.
  ctx:declare("lsp.capabilities", {
    kind = "value",
    desc = "Client capabilities advertised to language servers",
    native = function()
      return vim.lsp.protocol.make_client_capabilities()
    end,
  })

  ctx:declare("lsp.servers", {
    kind = "state",
    desc = "Language server registration",
    native = function()
      return function()
        M.register(ctx, true)
      end
    end,
  })

  -- Per-buffer behaviour, identical on both paths: it only ever runs when a
  -- server actually attaches, so it costs nothing when there is none.
  ctx:autocmd("LspAttach", {
    group = ctx:augroup("attach"),
    desc = "Inlay hints and document highlight",
    callback = function(event)
      local client = vim.lsp.get_client_by_id(event.data.client_id)
      if not client then
        return
      end

      if client:supports_method("textDocument/inlayHint") then
        -- A second hint-serving client can take ownership of the buffer, so the
        -- state starts from scratch instead of keeping the loser's columns in it.
        if vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }) then
          vim.lsp.inlay_hint.enable(false, { bufnr = event.buf })
        end
        vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
      end

      -- Highlight the other occurrences of the symbol under the cursor. No
      -- window, no panel, just highlighting.
      if client:supports_method("textDocument/documentHighlight") then
        local group = vim.api.nvim_create_augroup("dohwa.editor.lsp.highlight." .. event.buf, { clear = true })
        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
          buffer = event.buf,
          group = group,
          callback = vim.lsp.buf.document_highlight,
        })
        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
          buffer = event.buf,
          group = group,
          callback = vim.lsp.buf.clear_references,
        })
        vim.api.nvim_create_autocmd("LspDetach", {
          buffer = event.buf,
          once = true,
          callback = function()
            pcall(vim.api.nvim_del_augroup_by_id, group)
          end,
        })
      end
    end,
  })

  ctx:toggle("h", "Toggle: LSP inlay hints", function()
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
    vim.notify("inlay hints: " .. (enabled and "off" or "on"))
  end)
end

M.declare = function(ctx)
  -- Registration moves into setup(), which runs when lspconfig loads on
  -- BufReadPre, so opening Neovim on no file starts no server.
  ctx:override("lsp.servers")
end

M.plugins = function(ctx)
  return {
    {
      "neovim/nvim-lspconfig",
      dohwa_main = true,
      event = { "BufReadPre", "BufNewFile" },
      -- No dependencies, deliberately. Neovim 0.12 reads lspconfig's lsp/*.lua
      -- straight off the runtimepath and never requires its Lua module, so this
      -- plugin is a directory of 418 server defaults rather than code. Mason is
      -- an installer, not a runtime dependency: having it here pulled
      -- mason.nvim (1.4 ms), mason-lspconfig (6.5 ms) and mason-registry into
      -- every single file opened, for nothing.
    },
    {
      "williamboman/mason.nvim",
      -- VeryLazy fires after the screen is drawn, so the cost stops being felt.
      -- The cmd list keeps :Mason working even if that event never arrives.
      event = "VeryLazy",
      cmd = {
        "Mason", "MasonInstall", "MasonUpdate",
        "MasonUninstall", "MasonUninstallAll", "MasonLog",
      },
      opts = {
        ui = {
          border = ctx.ui.border,
          icons = {
            package_installed = ctx.ui.icons.ui.package_installed,
            package_pending = ctx.ui.icons.ui.package_pending,
            package_uninstalled = ctx.ui.icons.ui.package_uninstalled,
          },
        },
      },
    },
    {
      "williamboman/mason-lspconfig.nvim",
      event = "VeryLazy",
      dependencies = { "williamboman/mason.nvim" },
      config = function()
        require("mason-lspconfig").setup({
          ensure_installed = vim.tbl_keys(M.servers),
          -- Deliberately off: this module enables servers itself, with the
          -- filetypes and settings from its own table.
          automatic_enable = false,
        })

        -- Installs are asynchronous and finish long after BufReadPre registered
        -- whatever was already on PATH. Re-register when one lands, so the next
        -- buffer picks the server up. It cannot attach to buffers that are
        -- already open: vim.lsp.enable() only acts on subsequent FileType
        -- events, which is why registration still happens in setup().
        require("mason-registry"):on("package:install:success", function()
          vim.schedule(function()
            M.register(ctx, true)
          end)
        end)
      end,
    },
  }
end

M.setup = function(ctx)
  -- Only what is actually installed. This used to register everything on the
  -- assumption that Mason had already run by now; with Mason deferred to
  -- VeryLazy that is no longer true, and enabling a server whose binary is
  -- missing makes Neovim fail to spawn it. add_mason_to_path() runs first, so
  -- binaries Mason installed earlier are still found.
  M.register(ctx, true)
end

return M
