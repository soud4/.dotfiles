--- Language servers: what to start, for which filetypes, and how.
---
--- Data, plus the one function that registers it. Two plugin files read this:
--- plugins/lspconfig.lua starts these servers, plugins/mason_lspconfig.lua
--- installs them. Keeping the table here means adding a server is one edit in
--- one place instead of two lists that drift apart.
local M = {}

--- Everything needed to start each server: how, for which filetypes, and what
--- marks a project root.
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

--- Mason installs into its own bin directory. Putting it on PATH means servers
--- Mason installed earlier can be started before the Mason plugin loads.
local function add_mason_to_path()
  local bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
  if vim.uv.fs_stat(bin) and not vim.env.PATH:find(bin, 1, true) then
    vim.env.PATH = bin .. ":" .. vim.env.PATH
  end
end

--- Register and enable servers with the native API.
---
--- `only_available` is not optional in practice: with Mason deferred to
--- VeryLazy it is no longer true that everything is installed by now, and
--- enabling a server whose binary is missing makes Neovim fail to spawn it.
--- add_mason_to_path() runs first, so binaries Mason installed earlier are found.
---
--- Se puede llamar en cualquier momento, tambien con buffers ya abiertos:
--- `vim.lsp.enable()` termina con `vim.cmd.doautoall("nvim.lsp.enable FileType")`
--- (vim/lsp.lua), asi que retro-attachea a lo que ya este abierto. La unica
--- condicion es `vim.v.vim_did_enter == 1 or vim.fn.did_filetype() == 1`: si se
--- llama *durante* el arranque, antes de VimEnter, ese doautoall se salta y solo
--- sirve para los FileType siguientes.
function M.register()
  add_mason_to_path()
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  if ok then
    capabilities = cmp_lsp.default_capabilities()
  end
  for name, config in pairs(M.servers) do
    if vim.fn.executable(config.cmd[1]) == 1 then
      vim.lsp.config(name, vim.tbl_extend("force", config, { capabilities = capabilities }))
      vim.lsp.enable(name)
    end
  end
end

return M
