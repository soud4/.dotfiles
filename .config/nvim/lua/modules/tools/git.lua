--- Passive git signals: changed lines in the sign column, hunk navigation and
--- diffs on demand. Real git work still happens in the terminal.
---
--- This is the one module with no full native floor — Neovim has no built-in
--- hunk tracking. What it can do natively it does (blame and diff through the
--- git CLI); the rest is declared `optional`, so with the module off those
--- features resolve to nothing instead of erroring.
local function git_root()
  return vim.fs.root(vim.api.nvim_buf_get_name(0), ".git")
end

--- Run git in the buffer's repository and return stdout lines.
local function git(args)
  local root = git_root()
  if not root then
    return nil, "not a git repository"
  end
  local result = vim.system({ "git", "-C", root, unpack(args) }, { text = true }):wait()
  if result.code ~= 0 then
    return nil, (result.stderr or ""):gsub("%s+$", "")
  end
  return vim.split(result.stdout or "", "\n", { trimempty = true })
end

return {
  description = "Git signs and hunks",

  native = function(ctx)
    ctx:reserve("<leader>g", "Git")

    ctx:declare("git.blame_line", {
      desc = "Blame the current line",
      -- The CLI answers this perfectly well without a plugin.
      native = function()
        return function()
          local line = vim.fn.line(".")
          local file = vim.api.nvim_buf_get_name(0)
          local out, err = git({ "blame", "-L", line .. "," .. line, "--", file })
          if not out then
            return vim.notify(err or "blame failed", vim.log.levels.WARN)
          end
          vim.notify(out[1] or "no blame information")
        end
      end,
    })

    ctx:declare("git.diff_file", {
      desc = "Diff this file",
      native = function()
        return function()
          local file = vim.api.nvim_buf_get_name(0)
          local out, err = git({ "diff", "--", file })
          if not out then
            return vim.notify(err or "diff failed", vim.log.levels.WARN)
          end
          if #out == 0 then
            return vim.notify("no changes")
          end
          require("dohwa.popup").show(out, { title = "git diff", filetype = "diff" })
        end
      end,
    })

    -- No native equivalent exists for these; they simply do nothing when the
    -- plugin is absent, and :checkhealth dohwa says so.
    for name, desc in pairs({
      ["git.preview_hunk"] = "Preview hunk",
      ["git.reset_hunk"] = "Reset hunk",
      ["git.reset_buffer"] = "Reset file",
      ["git.hunk_next"] = "Next hunk",
      ["git.hunk_prev"] = "Previous hunk",
      ["git.select_hunk"] = "Hunk as a text object",
    }) do
      ctx:declare(name, { desc = desc, optional = true })
    end

    ctx:slot("n", "<leader>gp", "git.preview_hunk")
    ctx:slot("n", "<leader>gb", "git.blame_line")
    ctx:slot("n", "<leader>gd", "git.diff_file")
    ctx:slot({ "n", "v" }, "<leader>gr", "git.reset_hunk")
    ctx:slot("n", "<leader>gR", "git.reset_buffer")

    ctx:jump("h", "hunk", {
      next = function()
        ctx:call("git.hunk_next")
      end,
      prev = function()
        ctx:call("git.hunk_prev")
      end,
    })
    ctx:textobject("h", "hunk", {
      inner = function()
        ctx:call("git.select_hunk")
      end,
    })
  end,

  declare = function(ctx)
    local function gs(method, ...)
      local args = { ... }
      return function()
        return function()
          require("gitsigns")[method](unpack(args))
        end
      end
    end

    ctx:implement("git.preview_hunk", 50, gs("preview_hunk"))
    ctx:implement("git.reset_hunk", 50, gs("reset_hunk"))
    ctx:implement("git.reset_buffer", 50, gs("reset_buffer"))
    ctx:implement("git.select_hunk", 50, gs("select_hunk"))
    ctx:implement("git.blame_line", 50, function()
      return function()
        require("gitsigns").blame_line({ full = true })
      end
    end)
    ctx:implement("git.diff_file", 50, gs("diffthis"))

    -- Hunk navigation respects diff mode, where ]c/[c are the right motions.
    local function nav(direction, builtin)
      return function()
        return function()
          if vim.wo.diff then
            return vim.cmd.normal({ builtin, bang = true })
          end
          require("gitsigns").nav_hunk(direction)
        end
      end
    end
    ctx:implement("git.hunk_next", 50, nav("next", "]c"))
    ctx:implement("git.hunk_prev", 50, nav("prev", "[c"))

    -- Feeds the statusline. Declared by ui.statusline, which is what consumes it.
    ctx:implement("git.diffstat", 50, function()
      return function()
        local dict = vim.b.gitsigns_status_dict
        if not dict then
          return nil
        end
        return { added = dict.added, changed = dict.changed, removed = dict.removed }
      end
    end)

    ctx:toggle("b", "Toggle: inline git blame", function()
      require("gitsigns").toggle_current_line_blame()
    end)
  end,

  plugins = function(ctx)
    return {
      {
        "lewis6991/gitsigns.nvim",
        event = { "BufReadPre", "BufNewFile" },
        opts = {
          -- Thin signs fit the column 'signcolumn=yes' already reserves, so
          -- they never shift the text.
          signs = {
            add = { text = ctx.ui.icons.git.signs.add },
            change = { text = ctx.ui.icons.git.signs.change },
            delete = { text = ctx.ui.icons.git.signs.delete },
            topdelete = { text = ctx.ui.icons.git.signs.topdelete },
            changedelete = { text = ctx.ui.icons.git.signs.changedelete },
            untracked = { text = ctx.ui.icons.git.signs.untracked },
          },
          signs_staged_enable = true,
          -- Off by default: permanent blame is visual noise. <leader>tb toggles it.
          current_line_blame = false,
          current_line_blame_opts = { virt_text_pos = "eol", delay = 300 },
          preview_config = { border = ctx.ui.border },
        },
      },
    }
  end,
}
