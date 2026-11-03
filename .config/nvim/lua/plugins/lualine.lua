return {
  "nvim-lualine/lualine.nvim",
  lazy = false,
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    options = {
      component_separators = "",
      section_separators = "",
      globalstatus = true,
      padding = 1,
      disabled_filetypes = {
        statusline = { "neo-tree" },
      },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "filename", "branch", "diff" },
      lualine_x = { "diagnostics", "lsp_status", "fileformat", "searchcount" },
      lualine_y = { "filetype", "progress" },
      lualine_z = { "location" },
    },
  },
}
