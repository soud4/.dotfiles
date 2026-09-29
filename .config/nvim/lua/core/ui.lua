--- Shared visual tokens.
---
--- Plain data, required directly rather than discovered as a module: these
--- values are needed while modules are still declaring themselves. Everything
--- that draws a border or an icon reads from here, so the look stays coherent
--- when a module is switched off and its native fallback takes over.
---
--- Previously `"single"` was repeated in five files and the diagnostic icons
--- existed in three copies.
return {
  border = "single",

  icons = {
    diagnostics = {
      [vim.diagnostic.severity.ERROR] = " ",
      [vim.diagnostic.severity.WARN] = " ",
      [vim.diagnostic.severity.INFO] = " ",
      [vim.diagnostic.severity.HINT] = " ",
    },

    -- Same glyphs keyed by name, for consumers that want strings.
    severity = {
      error = " ",
      warn = " ",
      info = " ",
      hint = " ",
    },

    git = {
      branch = "",
      added = " ",
      modified = " ",
      removed = " ",
      signs = {
        add = "│",
        change = "│",
        delete = "_",
        topdelete = "‾",
        changedelete = "~",
        untracked = "┆",
      },
    },

    file = {
      modified = " ●",
      readonly = " 󰌾",
      unnamed = "[No Name]",
    },

    ui = {
      mode = "",
      lsp = "󰒋 ",
      folder = " ",
      position = " ",
      prompt = "   ",
      selection = " ❯ ",
      entry = "   ",
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },

    kinds = {
      Namespace = "󰌗",
      Text = "󰉿",
      Method = "󰆧",
      Function = "󰆧",
      Constructor = "",
      Field = "󰜢",
      Variable = "󰀫",
      Class = "󰠱",
      Interface = "",
      Module = "",
      Property = "󰜢",
      Unit = "󰑭",
      Value = "󰎠",
      Enum = "",
      Keyword = "󰌋",
      Snippet = "",
      Color = "󱓻",
      File = "󰈚",
      Reference = "󰈇",
      Folder = "󰉋",
      EnumMember = "",
      Constant = "󰏿",
      Struct = "󰙅",
      Event = "",
      Operator = "󰆕",
      TypeParameter = "󰊄",
      Table = "",
      Object = "󰅩",
      Tag = "",
      Array = "[]",
      Boolean = "",
      Number = "",
      Null = "󰟢",
      String = "󰉿",
      Package = "",
    },
  },
}
