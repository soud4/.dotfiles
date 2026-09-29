--- Autocommands that belong to the editor itself.
return {
  description = "Core autocommands",

  native = function(ctx)
    ctx:autocmd("TextYankPost", {
      group = ctx:augroup("yank"),
      desc = "Briefly highlight yanked text",
      callback = function()
        vim.hl.on_yank({ higroup = "IncSearch", timeout = 150 })
      end,
    })

    ctx:autocmd("BufReadPost", {
      group = ctx:augroup("cursor"),
      desc = "Restore the last cursor position",
      callback = function(args)
        local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
        if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
          pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
      end,
    })

    ctx:autocmd("FileType", {
      group = ctx:augroup("quickclose"),
      desc = "Close auxiliary windows with q",
      pattern = { "help", "lspinfo", "man", "notify", "qf", "checkhealth", "dohwa" },
      callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = event.buf, silent = true })
      end,
    })

    -- 'autoread' alone is not enough: Neovim only looks at the disk when asked.
    -- This matters when a CLI is editing the same file from another tmux pane.
    ctx:autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter", "CursorHold" }, {
      group = ctx:augroup("reload"),
      desc = "Reload the buffer when the file changed on disk",
      callback = function()
        if vim.bo.buftype == "" and vim.fn.mode() ~= "c" then
          -- vim.schedule is required: a :checktime issued from inside an
          -- autocommand is deferred and the buffer never actually reloads.
          vim.schedule(function()
            pcall(vim.cmd.checktime)
          end)
        end
      end,
    })

    ctx:autocmd("FileChangedShellPost", {
      group = ctx:augroup("reload.notify"),
      desc = "Say so when a file was reloaded from disk",
      callback = function()
        vim.notify("File reloaded from disk", vim.log.levels.WARN)
      end,
    })
  end,
}
