vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Node portable, visible solo dentro de Neovim (para Mason y LSPs).
local node_root = vim.fs.joinpath(vim.env.HOME, ".local", "opt", "node")
local node_bin = vim.fs.joinpath(node_root, "bin")
if vim.uv.fs_stat(vim.fs.joinpath(node_bin, "node")) then
  vim.env.PATH = node_bin .. ":" .. vim.env.PATH
  vim.env.npm_config_cache = vim.fs.joinpath(node_root, ".npm")
end

-- Binarios de Mason, sin tener que cargar Mason.
local mason_bin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "bin")
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

require("config.options")
require("config.hooks")
require("config.keymaps")
require("config.devcontainer").setup()

-- lazy.nvim bootstrap.
local lazy_path = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim")
if not vim.uv.fs_stat(lazy_path) then
  local out = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazy_path,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazy_path)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "gruvbox", "retrobox" } },
  checker = { enabled = false },
  rocks = { enabled = false },
  change_detection = { notify = false },
  ui = { border = "single" },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" },
    },
  },
})
