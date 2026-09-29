local Loader = require("dohwa.loader")

--- lazy.nvim as a plugin loader. Keeps the lockfile and the event-based lazy
--- loading; Dohwa only decides *which* specs it is handed.
---@class LazyLoader : Loader
local LazyLoader = Loader:extend("LazyLoader")

local LAZY_URL = "https://github.com/folke/lazy.nvim.git"

function LazyLoader:id()
  return "lazy"
end

--- Clone lazy.nvim on first run and put it on the runtimepath.
---@return boolean ok, string|nil err
function LazyLoader:bootstrap()
  local path = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lazy.nvim")
  local uv = vim.uv or vim.loop
  if not uv.fs_stat(path) then
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", LAZY_URL, path })
    if vim.v.shell_error ~= 0 then
      return false, out
    end
  end
  vim.opt.rtp:prepend(path)
  return true
end

function LazyLoader:install(specs)
  self.specs = specs
  local ok, err = self:bootstrap()
  if not ok then
    self.dohwa:log("loader.lazy", "error", "could not bootstrap lazy.nvim: " .. tostring(err))
    return false
  end
  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    self.dohwa:log("loader.lazy", "error", "lazy.nvim is not loadable: " .. tostring(lazy))
    return false
  end
  lazy.setup({
    spec = specs,
    install = { colorscheme = { "retrobox" } },
    checker = { enabled = true, notify = false },
    change_detection = { notify = false },
    performance = {
      rtp = {
        disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
      },
    },
  })
  return true
end

function LazyLoader:is_loaded(name)
  local ok, config = pcall(require, "lazy.core.config")
  if not ok then
    return false
  end
  local plugin = config.plugins[name]
  return plugin ~= nil and plugin._.loaded ~= nil
end

return LazyLoader
