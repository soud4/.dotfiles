local augroup = vim.api.nvim_create_augroup("core_hooks", { clear = true })
local hook = vim.api.nvim_create_autocmd

-- Restaurar la última posición del cursor
hook("BufReadPost", {
  group = augroup,
  desc = "Restore last cursor position",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Cerrar ventanas de utilidad rápidamente con 'q'
hook("FileType", {
  group = augroup,
  pattern = { "help", "lspinfo", "man", "notify", "qf", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- Activar conceal (ocultar formato) en Markdown y LaTeX
hook("FileType", {
  group = augroup,
  pattern = { "markdown", "tex" },
  callback = function()
    vim.opt_local.conceallevel = 2
  end,
})
