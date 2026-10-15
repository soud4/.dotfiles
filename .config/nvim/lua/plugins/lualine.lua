--- Statusline.

-- 1. datos: los mismos glifos que usan el sign column y los otros plugins,
-- escritos aca a proposito (ver README, "Un plugin por archivo").
local icons = {
  mode = "",
  lsp = "󰒋 ",
  folder = " ",
  position = " ",
  file = {
    modified = " ●",
    readonly = " 󰌾",
    unnamed = "[No Name]",
  },
  git = {
    branch = "",
    added = " ",
    modified = " ",
    removed = " ",
  },
  severity = {
    error = " ",
    warn = " ",
    info = " ",
    hint = " ",
  },
}

-- 2. helpers: componentes que se calculan en cada redraw.
local function lsp_clients()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    names[#names + 1] = client.name
  end
  return #names > 0 and (icons.lsp .. table.concat(names, ", ")) or ""
end

local function cwd_name()
  return icons.folder .. vim.fn.fnamemodify(vim.uv.cwd() or "", ":t")
end

local function cursor_position()
  return ("%s%d:%d"):format(icons.position, vim.fn.line("."), vim.fn.virtcol("."))
end

local function with_mode_icon(s)
  return icons.mode .. " " .. s
end

-- 3. el spec: tabla plana. Las funciones de arriba entran por referencia, asi
-- que esto no necesita ser `opts = function()`.
return {
  "nvim-lualine/lualine.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      theme = "auto",
      component_separators = "",
      section_separators = "",
      icons_enabled = true,
      globalstatus = true,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "neo-tree", "NvimTree" } },
    },
    sections = {
      lualine_a = {
        { "mode", fmt = with_mode_icon, padding = { left = 1, right = 1 } },
      },
      lualine_b = {
        { "filename", file_status = true, path = 0, symbols = icons.file },
        { "branch", icon = icons.git.branch },
        {
          "diff",
          symbols = {
            added = icons.git.added,
            modified = icons.git.modified,
            removed = icons.git.removed,
          },
        },
      },
      lualine_c = {},
      lualine_x = {
        { "diagnostics", sources = { "nvim_diagnostic" }, symbols = icons.severity },
        { lsp_clients, color = { gui = "bold" } },
        { cwd_name },
      },
      lualine_y = { { "filetype", colored = true } },
      lualine_z = { { cursor_position } },
    },
  },
}
