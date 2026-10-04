--- Formatting.
---
--- Native floor: `'formatprg'` is set per filetype to whichever formatter is
--- actually installed, so `gq` and the `format.buffer` feature keep working
--- through the built-in filter mechanism. Format-on-save is a plain
--- BufWritePre autocommand.
---
--- `vim.g.dohwa_format_on_save` is shared on purpose: it is genuinely global
--- state, and both the native path and conform read the same switch, so
--- <leader>tf means the same thing either way.
local PROGRAMS = {
  lua = { "stylua -" },
  sh = { "shfmt -" },
  bash = { "shfmt -" },
  c = { "clang-format" },
  cpp = { "clang-format" },
}

--- prettierd and prettier need the filename to pick a parser, so these are
--- resolved per buffer rather than per filetype.
local PRETTIER_FILETYPES = {
  "javascript", "typescript", "javascriptreact", "typescriptreact",
  "html", "css", "scss", "json", "markdown", "yaml", "vue",
}

local function formatprg_for(filetype, file)
  local candidates = PROGRAMS[filetype]
  if candidates then
    for _, program in ipairs(candidates) do
      if vim.fn.executable(program:match("^%S+")) == 1 then
        return program
      end
    end
    return nil
  end
  if vim.tbl_contains(PRETTIER_FILETYPES, filetype) then
    for _, program in ipairs({ "prettierd", "prettier" }) do
      if vim.fn.executable(program) == 1 then
        return program == "prettierd" and ("prettierd " .. file)
          or ("prettier --stdin-filepath " .. vim.fn.shellescape(file))
      end
    end
  end
end

return {
  description = "Formatting",

  native = function(ctx)
    if vim.g.dohwa_format_on_save == nil then
      vim.g.dohwa_format_on_save = true
    end

    ctx:autocmd("FileType", {
      group = ctx:augroup("formatprg"),
      desc = "Point 'formatprg' at an installed formatter",
      callback = function(event)
        local program = formatprg_for(vim.bo[event.buf].filetype, vim.api.nvim_buf_get_name(event.buf))
        if program then
          vim.bo[event.buf].formatprg = program
        end
      end,
    })

    ctx:declare("format.on_save", {
      kind = "state",
      desc = "Format on save",
      native = function()
        return function()
          ctx:autocmd("BufWritePre", {
            group = ctx:augroup("on_save"),
            desc = "Format the buffer before writing",
            callback = function()
              if vim.g.dohwa_format_on_save ~= false then
                ctx:call("format.buffer")
              end
            end,
          })
        end
      end,
    })

    -- Useful when a CLI is editing the same file from another pane and you do
    -- not want Neovim reformatting on top of its changes.
    ctx:toggle("f", "Toggle: format on save", function()
      vim.g.dohwa_format_on_save = vim.g.dohwa_format_on_save == false
      vim.notify("format on save: " .. (vim.g.dohwa_format_on_save and "on" or "off"))
    end)
  end,

  declare = function(ctx)
    ctx:implement("format.buffer", 50, function()
      return function()
        require("conform").format({ async = true, lsp_format = "fallback" })
      end
    end)
    -- conform brings its own format_on_save, driven by the same flag.
    ctx:override("format.on_save")
  end,

  plugins = function()
    return {
      {
        "stevearc/conform.nvim",
        event = { "BufWritePre" },
        cmd = { "ConformInfo" },
        opts = {
          format_on_save = function()
            if vim.g.dohwa_format_on_save == false then
              return nil
            end
            return { timeout_ms = 1000, lsp_format = "fallback" }
          end,
          -- stop_after_first runs the first formatter present on the system.
          formatters_by_ft = {
            lua = { "stylua" },
            php = { "pint", "php_cs_fixer", stop_after_first = true },
            javascript = { "prettierd", "prettier", stop_after_first = true },
            typescript = { "prettierd", "prettier", stop_after_first = true },
            javascriptreact = { "prettierd", "prettier", stop_after_first = true },
            typescriptreact = { "prettierd", "prettier", stop_after_first = true },
            vue = { "prettierd", "prettier", stop_after_first = true },
            html = { "prettierd", "prettier", stop_after_first = true },
            css = { "prettierd", "prettier", stop_after_first = true },
            scss = { "prettierd", "prettier", stop_after_first = true },
            json = { "prettierd", "prettier", stop_after_first = true },
            markdown = { "prettierd", "prettier", stop_after_first = true },
            c = { "clang-format" },
            cpp = { "clang-format" },
            sh = { "shfmt" },
          },
        },
      },
    }
  end,
}
