local function cp(code)
  return vim.fn.nr2char(code)
end

local icons = {
  Namespace = cp(0xF0317),
  Text = cp(0xF027F),
  Method = cp(0xF01A7),
  Function = cp(0xF01A7),
  Constructor = cp(0xF423),
  Field = cp(0xF0722),
  Variable = cp(0xF002B),
  Class = cp(0xF0831),
  Interface = cp(0xF0E8),
  Module = cp(0xF487),
  Property = cp(0xF0722),
  Unit = cp(0xF046D),
  Value = cp(0xF03A0),
  Enum = cp(0xF15D),
  Keyword = cp(0xF030B),
  Snippet = cp(0xF44F),
  Color = cp(0xF14FB),
  File = cp(0xF021A),
  Reference = cp(0xF0207),
  Folder = cp(0xF024B),
  EnumMember = cp(0xF15D),
  Constant = cp(0xF03FF),
  Struct = cp(0xF0645),
  Event = cp(0xF0E7),
  Operator = cp(0xF0195),
  TypeParameter = cp(0xF0284),
  Table = cp(0xF0CE),
  Object = cp(0xF0169),
  Tag = cp(0xF02B),
  Array = "[]",
  Boolean = cp(0xF042),
  Number = cp(0xF292),
  Null = cp(0xF07E2),
  String = cp(0xF027F),
  Calendar = cp(0xF073),
  Watch = cp(0xF0954),
  Package = cp(0xE624),
}

local function format_item(entry, item)
  local kind = item.kind or ""
  item.kind = (" %s "):format(icons[kind] or icons.File)
  item.menu = ("%-9s [%s]"):format(kind, entry.source.name)
  if #item.abbr > 38 then
    item.abbr = item.abbr:sub(1, 38) .. "…"
  end
  return item
end

return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
  },
  config = function()
    local cmp = require("cmp")
    local luasnip = require("luasnip")

    require("luasnip.loaders.from_vscode").lazy_load()

    -- Colores de los iconos según el tipo.
    local hl = vim.api.nvim_set_hl
    hl(0, "CmpItemKindFunction", { link = "Function" })
    hl(0, "CmpItemKindMethod", { link = "Function" })
    hl(0, "CmpItemKindConstructor", { link = "Function" })
    hl(0, "CmpItemKindVariable", { link = "@variable" })
    hl(0, "CmpItemKindField", { link = "@variable" })
    hl(0, "CmpItemKindProperty", { link = "@variable" })
    hl(0, "CmpItemKindKeyword", { link = "Keyword" })
    hl(0, "CmpItemKindClass", { link = "Type" })
    hl(0, "CmpItemKindInterface", { link = "Type" })
    hl(0, "CmpItemKindStruct", { link = "Type" })
    hl(0, "CmpItemKindEnum", { link = "Type" })
    hl(0, "CmpItemKindConstant", { link = "Constant" })
    hl(0, "CmpItemKindSnippet", { link = "String" })
    hl(0, "CmpItemKindModule", { link = "@module" })
    hl(0, "CmpItemMenu", { link = "Comment" })

    local function is_completion_enabled()
      local buftype = vim.api.nvim_get_option_value("buftype", { buf = 0 })
      if buftype == "prompt" or vim.fn.reg_recording() ~= "" or vim.fn.reg_executing() ~= "" then
        return false
      end

      if vim.api.nvim_get_mode().mode == "c" then
        return true
      end

      local context = require("cmp.config.context")
      return not context.in_treesitter_capture("comment") and not context.in_syntax_group("Comment")
    end

    cmp.setup({
      enabled = is_completion_enabled,
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      completion = { completeopt = "menu,menuone,noinsert" },

      performance = {
        max_view_entries = 15,
        debounce = 60,
        throttle = 30,
      },

      window = {
        completion = cmp.config.window.bordered({ border = "single", scrollbar = false }),
        documentation = cmp.config.window.bordered({ border = "single", max_width = 80, max_height = 20 }),
      },
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = format_item,
        expandable_indicator = false,
      },

      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
      }),

      sources = {
        { name = "nvim_lsp", priority = 1000 },
        { name = "alpinejs", priority = 800 },
        { name = "luasnip", priority = 750 },
        { name = "path", priority = 500 },
        { name = "buffer", priority = 250, keyword_length = 2 },
      },
    })
  end,
}
