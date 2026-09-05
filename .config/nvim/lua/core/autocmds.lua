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

