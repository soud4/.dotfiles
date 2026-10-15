--- Key hints.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  keys = {
    {
      "<leader>??",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Show available keys",
    },
  },
  opts = {
    preset = "helix", -- compact side panel rather than the full screen
    delay = 500, -- long enough to stay out of the way when you know the key
    icons = { mappings = false },
    win = { border = "single" },
    -- Written out rather than derived from a registry. Twelve lines against
    -- 604 for the broker that used to generate them.
    spec = {
      { "<leader>c", group = "Code" },
      { "<leader>d", group = "Diagnostics" },
      { "<leader>f", group = "Find" },
      { "<leader>F", group = "Native find" },
      { "<leader>g", group = "Git" },
      { "<leader>s", group = "Swap (tree-sitter)" },
      { "<leader>t", group = "Toggles" },
      { "<leader>=", group = "Format" },
      { "<leader>?", group = "Key hints" },
      { "]", group = "Next" },
      { "[", group = "Previous" },
    },
  },
}
