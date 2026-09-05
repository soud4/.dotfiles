-- Opciones de neovim

local opt = vim.opt

-- Interfaz
opt.number = true -- mostrar número de línea
opt.relativenumber = true -- mostrar número relativo
opt.cursorline = true -- resaltar línea actual
opt.termguicolors = true -- colores RGB en terminal
opt.signcolumn = "yes" -- columna de signos siempre visible
opt.wrap = false -- no envolver líneas largas

-- Sangría y tabulación
opt.expandtab = true -- convertir tabs en espacios
opt.shiftwidth = 4 -- número de espacios por sangría
opt.tabstop = 4 -- mostrar ancho del tab como 4 espacios
opt.smartindent = true -- indentación inteligente

-- Búsqueda
opt.ignorecase = true -- ignorar mayúsculas al buscar...
opt.smartcase = true -- ...a menos que haya al menos una mayúscula
opt.hlsearch = true -- resaltar coincidencias de búsqueda
opt.incsearch = true -- búsqueda incremental en tiempo real
opt.inccommand = "split" -- vista previa en vivo al reemplazar texto (:%s/a/b/g)

-- Divisiones de ventana
opt.splitright = true -- nuevas ventanas verticales a la derecha
opt.splitbelow = true -- nuevas ventanas horizontales abajo

-- Archivos e historial
opt.undofile = true -- usar historial persistente (deshacer tras reiniciar)

-- Experiencia de usuario y rendimiento
opt.updatetime = 250 -- reduce lag para eventos como diagnósticos y CursorHold
opt.timeoutlen = 400 -- tiempo de espera para combinaciones de teclas
opt.scrolloff = 8 -- mínimo de líneas arriba/abajo del cursor
opt.sidescrolloff = 8 -- mínimo de columnas a los lados del cursor
opt.mouse = "a" -- habilitar mouse
opt.clipboard = "unnamedplus" -- sincronizar con el portapapeles del sistema

-- Apariencia
opt.showmode = false -- no mostrar -- INSERT -- (lo muestra lualine)
opt.cmdheight = 0 -- ocultar la línea de comandos cuando no se use
opt.laststatus = 3 -- una sola barra de estado global

-- Plegado de código con Treesitter
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldenable = false -- no iniciar con el código plegado al abrir archivos
opt.foldlevel = 99

