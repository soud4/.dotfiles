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


