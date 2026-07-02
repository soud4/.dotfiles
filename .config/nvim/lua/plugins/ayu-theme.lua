
return {
  {
    "Shatur/neovim-ayu",
    priority = 1000, -- para cargar el tema antes que otros plugins
    config = function()
      require("ayu").setup({
        mirage = dark, -- true para usar el modo mirage (oscuro suave), false para dark clásico
        overrides = {
            Normal = { bg = "none" },
            NormalNC = { bg = "none" },
            SignColumn = { bg = "none" },
            VertSplit = { bg = "none" },
            EndOfBuffer = { bg = "none" },
            LineNr = { bg = "none" },
        },
        term_colors = true,
      })

      -- Aplica el tema
      vim.cmd("colorscheme ayu")
    end,
  },
}
