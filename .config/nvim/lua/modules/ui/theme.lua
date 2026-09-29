--- Colour scheme.
---
--- Native floor: `retrobox`, which ships with Neovim and is a gruvbox in all
--- but name, so switching this module off changes the palette slightly and
--- nothing else.
return {
  description = "Colour scheme",

  native = function(ctx)
    ctx:declare("ui.colorscheme", {
      kind = "state",
      desc = "Colour scheme",
      native = function()
        return function()
          vim.o.background = "dark"
          vim.cmd.colorscheme("retrobox")
          -- Match the transparent look the plugin configuration uses.
          for _, group in ipairs({ "Normal", "NormalFloat", "SignColumn", "EndOfBuffer" }) do
            vim.api.nvim_set_hl(0, group, { bg = "none" })
          end
        end
      end,
    })
  end,

  declare = function(ctx)
    ctx:implement("ui.colorscheme", 50, function()
      return function()
        require("gruvbox").setup({
          terminal_colors = true,
          undercurl = true,
          underline = true,
          bold = true,
          italic = {
            strings = true,
            emphasis = true,
            comments = true,
            operators = false,
            folds = true,
          },
          strikethrough = true,
          invert_selection = false,
          inverse = true,
          contrast = "",
          dim_inactive = false,
          transparent_mode = true,
        })
        vim.cmd.colorscheme("gruvbox")
      end
    end)
  end,

  plugins = function()
    return {
      {
        "ellisonleao/gruvbox.nvim",
        lazy = false,
        priority = 1000,
      },
    }
  end,
}
