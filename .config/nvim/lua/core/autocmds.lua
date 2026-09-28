-- Comandos automáticos
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- 1. Resaltar texto brevemente al copiar (Yank)
autocmd("TextYankPost", {
	desc = "Resaltar texto copiado",
	group = augroup("HighlightYank", { clear = true }),
	callback = function()
		(vim.hl or vim.highlight).on_yank({ higroup = "IncSearch", timeout = 150 })
	end,
})

-- 2. Volver a la última posición del cursor al abrir un archivo
autocmd("BufReadPost", {
	desc = "Restaurar última posición del cursor",
	group = augroup("RestoreCursorPosition", { clear = true }),
	callback = function(args)
		local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
		local line_count = vim.api.nvim_buf_line_count(args.buf)
		if mark[1] > 0 and mark[1] <= line_count then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- 3. Cerrar buffers auxiliares pulsando 'q'
autocmd("FileType", {
	desc = "Cerrar ciertas ventanas con 'q'",
	group = augroup("CloseWithQ", { clear = true }),
	pattern = {
		"help",
		"lspinfo",
		"man",
		"notify",
		"qf",
		"checkhealth",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
	end,
})

-- 4. Detectar cambios hechos fuera de nvim (ej. Claude editando desde otro panel de tmux).
--    'autoread' por sí solo no basta: nvim sólo mira el disco cuando se lo pides con :checktime.
autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter", "CursorHold" }, {
	desc = "Recargar el buffer si el archivo cambió en disco",
	group = augroup("AutoRecargar", { clear = true }),
	callback = function()
		-- Sólo buffers de archivo real, y nunca mientras se escribe un comando
		if vim.bo.buftype == "" and vim.fn.mode() ~= "c" then
			-- vim.schedule es imprescindible: nvim aplaza un :checktime lanzado
			-- desde dentro de un autocmd y el buffer nunca llega a recargarse.
			vim.schedule(function()
				pcall(vim.cmd.checktime)
			end)
		end
	end,
})

-- 5. Avisar cuando un archivo se recargó solo, para no perder de vista el cambio
autocmd("FileChangedShellPost", {
	desc = "Notificar recarga externa",
	group = augroup("AvisoRecarga", { clear = true }),
	callback = function()
		vim.notify("Archivo recargado desde disco", vim.log.levels.WARN)
	end,
})

