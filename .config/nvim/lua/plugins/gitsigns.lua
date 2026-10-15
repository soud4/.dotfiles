--- Passive git signals: changed lines in the sign column, hunk navigation and
--- diffs on demand. Real git work still happens in the terminal.
local u = require("core.utils")

-- 1. datos

-- Thin signs fit the column 'signcolumn=yes' already reserves, so they never
-- shift the text.
local signs = {
  add = { text = "│" },
  change = { text = "│" },
  delete = { text = "_" },
  topdelete = { text = "‾" },
  changedelete = { text = "~" },
  untracked = { text = "┆" },
}

-- 2. helpers

--- Hunk navigation respects diff mode, where ]c/[c are the right motions and
--- gitsigns must get out of the way.
local function nav(direction, motion)
  return function()
    if vim.wo.diff then
      return vim.cmd.normal({ motion, bang = true })
    end
    require("gitsigns").nav_hunk(direction)
  end
end

--- Teclas locales al buffer, puestas cuando gitsigns attachea.
local function on_attach(buf)
  local gs = require("gitsigns")
  local map = u.buffmapper(buf)

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

--- Fuera de un repo gitsigns carga (3.7 ms), no encuentra nada y se
--- desattachea. Esto se evalua una vez, contra el cwd del arranque: si abris
--- nvim fuera de un repo y despues entras a uno, queda apagado esa sesion.
--- `.git` puede ser un directorio o un archivo (worktrees y submodulos), y
--- vim.fs.find sin `type` acepta ambos.
local function in_git_repo()
  return vim.fs.find(".git", { upward = true, path = vim.fn.getcwd() })[1] ~= nil
end

-- 3. el spec
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  cond = in_git_repo,
  opts = {
    signs = signs,
    signs_staged_enable = true,
    -- Off by default: permanent blame is visual noise. <leader>tb toggles it.
    current_line_blame = false,
    current_line_blame_opts = { virt_text_pos = "eol", delay = 300 },
    preview_config = { border = "single" },
    on_attach = on_attach,
  },
}
