local function group(name)
  return vim.api.nvim_create_augroup("config." .. name, { clear = true })
end

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group("yank"),
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group("cursor"),
  desc = "Restore the last cursor position",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group("quickclose"),
  pattern = { "help", "lspinfo", "man", "notify", "qf", "checkhealth" },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
  end,
})

-- 'autoread' solo mira el disco cuando se le pide.
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter", "CursorHold" }, {
  group = group("reload"),
  callback = function()
    if vim.bo.buftype == "" and vim.fn.mode() ~= "c" then
      -- Un :checktime dentro de un autocmd se difiere y no recarga; por eso el schedule.
      vim.schedule(function()
        pcall(vim.cmd.checktime)
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("FileChangedShellPost", {
  group = group("reload.notify"),
  callback = function()
    vim.notify("File reloaded from disk", vim.log.levels.WARN)
  end,
})
