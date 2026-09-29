-- Leader keys must be set before anything maps against them.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Running as root, skip the plugin manager entirely: Dohwa falls back to the
-- native implementation of every module, which is a complete editor on its own.
local uv = vim.uv or vim.loop
if uv.getuid() == 0 then
  vim.env.DOHWA_LOADER = "null"
end

require("dohwa"):boot()
