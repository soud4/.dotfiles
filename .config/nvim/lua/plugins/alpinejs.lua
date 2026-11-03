--- Soporte para Alpine.js v3 (Tree-sitter, nvim-cmp y snippets).
--- https://github.com/ConnorOnTheWeb/alpinejs.nvim

return {
  "connorontheweb/alpinejs.nvim",
  ft = {
    "html",
    "php",
    "blade",
    "templ",
    "astro",
    "javascript",
    "javascriptreact",
    "typescriptreact",
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "hrsh7th/nvim-cmp",
    "L3MON4D3/LuaSnip",
  },
  opts = {},
}
