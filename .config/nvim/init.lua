-- Establece líder antes de cualquier cosa

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Carga la configuración principal
-- require("core.lazy")

if vim.loop.getuid() ~= 0 then
	require("core.lazy")
end

-- Opciones y keymaps básicos
require("core.options")
require("core.keymaps")
require("core.autocmds")
