--- Markdown rendering in the buffer. <leader>tm lo alterna.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    completions = { lsp = { enabled = true } },
    heading = {
      sign = false,
      icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
      width = "block",
      min_width = 40,
      left_pad = 0,
      right_pad = 2,
    },
    code = {
      sign = false,
      width = "block",
      min_width = 60,
      right_pad = 2,
      border = "thin",
      language_pad = 1,
    },
    bullet = { icons = { "•", "◦", "▪", "▫" } },
    checkbox = {
      unchecked = { icon = "󰄱 " },
      checked = { icon = "󰱒 " },
    },
    pipe_table = { preset = "round", style = "full" },
    quote = { icon = "▌" },
    link = { hyperlink = "󰌷 ", image = "󰥶 ", email = "󰀓 " },
    anti_conceal = { enabled = true, above = 0, below = 0 },
    win_options = { showbreak = { default = "", rendered = "  " } },
    overrides = {
      buftype = { nofile = { enabled = false } },
    },
  },
}
