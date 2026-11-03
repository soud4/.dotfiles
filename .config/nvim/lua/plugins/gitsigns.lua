--- Git signs, hunk navigation and blame.

local function on_attach(buf)
  local gs = require("gitsigns")
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end
  -- En modo diff ]c/[c son las motions correctas.
  local function nav(direction, motion)
    return function()
      if vim.wo.diff then
        return vim.cmd.normal({ motion, bang = true })
      end
      gs.nav_hunk(direction)
    end
  end

  map("n", "]h", nav("next", "]c"), "Next hunk")
  map("n", "[h", nav("prev", "[c"), "Previous hunk")
  map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
  map("n", "<leader>gd", gs.diffthis, "Diff this file")
  map("n", "<leader>gb", function()
    gs.blame_line({ full = true })
  end, "Blame the current line")
  map({ "n", "v" }, "<leader>gr", gs.reset_hunk, "Reset hunk")
  map("n", "<leader>gR", gs.reset_buffer, "Reset file")
  map({ "o", "x" }, "ih", gs.select_hunk, "hunk")
  map({ "o", "x" }, "ah", gs.select_hunk, "hunk")
  map("n", "<leader>tb", gs.toggle_current_line_blame, "Toggle: inline git blame")
end

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "│" },
      change = { text = "│" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "┆" },
    },
    current_line_blame_opts = { virt_text_pos = "eol", delay = 300 },
    preview_config = { border = "single" },
    on_attach = on_attach,
  },
}
