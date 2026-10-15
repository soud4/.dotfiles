--- Makes Mason install the servers config/servers.lua declares.
local lsp = require("config.servers")

-- 1. helpers

--- Installs are asynchronous and finish long after register() enabled whatever
--- ya estaba en PATH. Re-register cuando cae uno nuevo. Esto si alcanza a los
--- buffers abiertos: a esta altura VimEnter ya paso, y vim.lsp.enable() hace
--- doautoall sobre su FileType (ver config/servers.lua).
local function reregister_on_install()
  require("mason-registry"):on("package:install:success", function()
    vim.schedule(lsp.register)
  end)
end

-- 2. el spec
return {
  "williamboman/mason-lspconfig.nvim",
  event = "VeryLazy",
  dependencies = { "williamboman/mason.nvim" },
  config = function()
    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(lsp.servers),
      -- Deliberately off: servers are enabled by plugins/lspconfig.lua, with
      -- the filetypes and settings from config/servers.lua.
      automatic_enable = false,
    })
    reregister_on_install()
  end,
}
