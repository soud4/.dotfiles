-- Opciones de neovim

local opt = vim.opt
local g = vim.g

-- Interfaz
opt.number = true -- mostrar número de línea
opt.relativenumber = true -- mostrar número relativo
opt.cursorline = true -- resaltar línea actual
opt.termguicolors = true -- colores RGB en terminal
opt.signcolumn = "yes" -- columna de signos siempre visible
opt.wrap = false -- no envolver líneas largas}

-- Sangría y tabulación
opt.expandtab = true -- convertir tabs en espacios
opt.shiftwidth = 4 -- número de espacios por sangría
opt.tabstop = 4 -- mostrar ancho del tab como 4 espacios
opt.smartindent = true -- indentación inteligente

-- Divisiones de ventana
opt.splitright = true -- nuevas ventanas verticales a la derecha
opt.splitbelow = true -- nuevas ventanas horizontales abajo

-- Archivos
-- opt.swapfile = false            -- no usar archivos swap
-- opt.backup = false              -- no usar backups
opt.undofile = true -- usar historial persistente

-- Completado y experiencia de usuario
opt.updatetime = 300 -- reduce lag para eventos como LSP
opt.timeoutlen = 500 -- tiempo de espera para mappings
opt.scrolloff = 8 -- mínimo de líneas arriba/abajo del cursor
opt.sidescrolloff = 8 -- mínimo de columnas a los lados del cursor
opt.mouse = "a" -- habilitar mouse
opt.clipboard = "unnamedplus" -- usar portapapeles del sistema

-- Apariencia
opt.showmode = false -- no mostrar -- INSERT -- (lo muestra lualine)
opt.cmdheight = 0 -- altura mínima de la línea de comandos (si lo soporta tu versión)
opt.laststatus = 3 -- una sola barra de estado global
