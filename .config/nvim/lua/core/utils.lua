--- Mechanisms shared by the plugin specs.
---
--- Directrices, no una capa de abstracción. Cada helper existe para usarse en
--- los locals *arriba* del `return` de un spec, de modo que el spec en sí quede
--- como una tabla plana de datos y no como código.
---
--- Tres reglas, para que esto no crezca sin control:
---
---  1. Aquí solo entra lo que tiene dos o más usos reales. Con un solo sitio de
---     llamada, escribilo inline: `require("conform").format({...})` dentro de
---     su propia función es más claro que cualquier helper.
---  2. Aquí no hay apariencia. El borde y los iconos se escriben en cada
---     archivo de plugin, a propósito; este módulo es mecanismo, no estilo.
---  3. Nada de aquí conoce ningún plugin concreto.
local M = {}

-- LuaJIT 2.1 tal como lo compila Neovim no trae `table.unpack` ni `table.pack`
-- (comprobado: ambos son nil, el `unpack` global sí existe). El fallback es
-- obligatorio, no defensivo.
local unpack = table.unpack or unpack

--- Constructor de llamadas diferidas a un módulo.
---
--- `M.defer(mod)` devuelve una función que *construye callbacks*, no resultados.
--- Ni el `require` ni la llamada ocurren hasta que se pulsa la tecla, y eso es
--- justamente lo que permite que el plugin siga descargado hasta el primer uso:
---
---     local builtin = M.defer("telescope.builtin")
---     keys = {
---       { "<leader>ff", builtin("find_files"), desc = "..." },
---       { "<leader>fc", builtin("find_files", { cwd = "..." }), desc = "..." },
---     }
---
--- Los argumentos quedan capturados cuando se construye el callback; el cuerpo
--- corre cuando se invoca. `select("#", ...)` conserva la cantidad real de
--- argumentos, así que un `nil` explícito en el medio no desplaza a los demás.
---
---@param mod string Nombre del módulo, tal como se lo pasarías a `require`.
---@return fun(name: string, ...): fun(): any
function M.defer(mod)
	return function(name, ...)
		local n = select("#", ...)
		local args = { ... }
		return function()
			return require(mod)[name](unpack(args, 1, n))
		end
	end
end

--- Constructor de keymaps locales a un buffer, para un `on_attach`.
---
--- Local al buffer a propósito: en un buffer sin servidor (o sin git), las
--- teclas conservan su significado nativo en vez de fallar.
---
---     local map = M.buffmapper(buf)
---     map("n", "gd", picker("lsp_definitions"), "Go to definition")
---
---@param buf integer
---@return fun(mode: string|string[], lhs: string, rhs: string|function, desc: string)
function M.buffmapper(buf)
	return function(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
	end
end

--- Grupo de autocomandos con nombre, que se limpia a sí mismo.
---
--- El prefijo `config.` mantiene todos los grupos de esta config juntos y
--- distinguibles en `:autocmd`. `clear = true` es lo que hace que recargar un
--- módulo no duplique sus autocomandos.
---
---@param name string Sin el prefijo: "cmp.highlights", "lsp.attach".
---@return integer
function M.augroup(name)
	return vim.api.nvim_create_augroup("config." .. name, { clear = true })
end

--- El aviso que acompana a un toggle: "<label>: on" / "<label>: off".
---
--- Lo comparten los siete toggles de config/keymaps.lua; tres de ellos son
--- opciones de ventana y usan toggle_wo, los otros cuatro llaman a esto
--- directamente porque cada uno consulta su estado por una API distinta.
---
---@param label string
---@param on boolean
function M.notify_state(label, on)
	vim.notify(label .. ": " .. (on and "on" or "off"))
end

--- Toggle de una opcion de ventana, con su aviso.
---
---     map("n", "<leader>tw", M.toggle_wo("wrap"), { desc = "Toggle: line wrap" })
---
--- Devuelve el callback, no el resultado: se construye una vez al definir la
--- tecla y lee `vim.wo` en el momento de pulsarla, asi que respeta la ventana
--- en la que estes.
---
---@param name string Nombre de la opcion, tal como la indexa `vim.wo`.
---@return fun()
function M.toggle_wo(name)
	return function()
		vim.wo[name] = not vim.wo[name]
		M.notify_state(name, vim.wo[name])
	end
end

return M
