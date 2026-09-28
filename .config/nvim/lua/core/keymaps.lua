-- Mapeos de teclado personalizados

local map = vim.keymap.set

-- Limpiar resaltado de búsqueda al pulsar Esc
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Limpiar resaltado de búsqueda" })

-- Navegación rápida entre ventanas divididas (Split navigation)
map("n", "<C-h>", "<C-w>h", { desc = "Mover a la ventana izquierda" })
map("n", "<C-j>", "<C-w>j", { desc = "Mover a la ventana inferior" })
map("n", "<C-k>", "<C-w>k", { desc = "Mover a la ventana superior" })
map("n", "<C-l>", "<C-w>l", { desc = "Mover a la ventana derecha" })

-- Mover bloques de código seleccionados en modo visual
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Mover bloque seleccionado abajo", silent = true })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Mover bloque seleccionado arriba", silent = true })

-- Mantener el cursor centrado al hacer scroll o buscar
map("n", "<C-d>", "<C-d>zz", { desc = "Bajar media página centrado" })
map("n", "<C-u>", "<C-u>zz", { desc = "Subir media página centrado" })
map("n", "n", "nzzzv", { desc = "Siguiente coincidencia centrada" })
map("n", "N", "Nzzzv", { desc = "Anterior coincidencia centrada" })

-- =============================================================================
-- INTERRUPTORES (<leader>t): apagar y encender lo que estorbe en cada momento
-- =============================================================================

-- Inlay hints: tipos inferidos y nombres de parámetros en gris
map("n", "<leader>th", function()
	local activo = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
	vim.lsp.inlay_hint.enable(not activo, { bufnr = 0 })
	vim.notify("Inlay hints: " .. (activo and "off" or "on"))
end, { desc = "Interruptor: Inlay hints del LSP" })

-- Formato al guardar (ver plugins/conform.lua).
-- Útil apagarlo cuando un CLI está editando el mismo archivo desde tmux.
map("n", "<leader>tf", function()
	vim.g.formato_al_guardar = vim.g.formato_al_guardar == false
	vim.notify("Formato al guardar: " .. (vim.g.formato_al_guardar and "on" or "off"))
end, { desc = "Interruptor: Formatear al guardar" })

-- Blame de git en línea (ver plugins/gitsigns.lua)
map("n", "<leader>tB", function()
	require("gitsigns").toggle_current_line_blame()
end, { desc = "Interruptor: Blame de git en línea" })

-- Ajuste de línea
map("n", "<leader>tw", function()
	vim.opt.wrap = not vim.opt.wrap:get()
	vim.notify("Ajuste de línea: " .. (vim.opt.wrap:get() and "on" or "off"))
end, { desc = "Interruptor: Ajuste de línea (wrap)" })

-- Diagnósticos, por si el archivo está lleno de errores y molestan
map("n", "<leader>td", function()
	local activo = vim.diagnostic.is_enabled()
	vim.diagnostic.enable(not activo)
	vim.notify("Diagnósticos: " .. (activo and "off" or "on"))
end, { desc = "Interruptor: Diagnósticos" })


