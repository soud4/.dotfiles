--- Completion and snippets.
local u = require("core.utils")

-- 1. datos

--- Un glifo por kind de item LSP, para la columna de kind del menu.
local icons = {
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
}

--- Etiqueta corta por fuente, para la columna de la derecha.
local source_labels = { nvim_lsp = "LSP", luasnip = "Snippet", buffer = "Buffer", path = "Path" }

--- Enlaces del menu a grupos de tree-sitter, en vez de colores fijos, para que
--- siga al colorscheme que este aplicado.
local highlight_links = {
  CmpItemKindFunction = "@function",
  CmpItemKindMethod = "@function.method",
  CmpItemKindVariable = "@variable",
  CmpItemKindKeyword = "@keyword",
  CmpItemKindSnippet = "@string",
  CmpItemKindClass = "@type",
  CmpItemKindInterface = "@type",
  CmpItemKindStruct = "@type",
  CmpItemKindProperty = "@property",
  CmpItemKindField = "@variable.member",
  CmpItemKindModule = "@module",
  CmpItemKindFile = "Directory",
  CmpItemKindFolder = "Directory",
  CmpItemAbbrMatch = "@keyword",
  CmpItemAbbrMatchFuzzy = "@keyword",
}

local window = {
  border = "single",
  winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
}

local sources = {
  { name = "nvim_lsp", priority = 1000 },
  { name = "luasnip", priority = 750 },
  { name = "path", priority = 500 },
  { name = "buffer", priority = 250, keyword_length = 2 },
}

local max_abbr_width = 38

-- 2. helpers

--- Re-enlazado en ColorScheme: sin eso, el menu pierde sus colores la primera
--- vez que cambia el tema.
local function apply_highlights()
  for from, to in pairs(highlight_links) do
    vim.api.nvim_set_hl(0, from, { link = to, default = false })
  end
end

--- Como se dibuja cada fila del menu: kind, texto, fuente.
local function format_item(entry, item)
  local kind = item.kind or ""
  item.kind = (" %s "):format(icons[kind] or icons.File)
  item.menu = ("%-9s [%s]"):format(kind, source_labels[entry.source.name] or entry.source.name)

  -- Preview de colores CSS/hex en la columna de kind.
  if kind == "Color" and entry.completion_item.documentation then
    local doc = entry.completion_item.documentation
    if type(doc) == "string" and doc:match("^#%x%x%x%x%x%x$") then
      local group = "HexColor_" .. doc:sub(2)
      vim.api.nvim_set_hl(0, group, { fg = doc })
      item.kind = " " .. icons.Color .. " "
      item.kind_hl_group = group
    end
  end

  if #item.abbr > max_abbr_width then
    item.abbr = item.abbr:sub(1, max_abbr_width) .. "…"
  end
  return item
end

--- Menu, despues salto de snippet, despues lo que <Tab> haga normalmente.
local function snippet_aware(cmp, luasnip, forward)
  return cmp.mapping(function(fallback)
    if cmp.visible() then
      return forward and cmp.select_next_item() or cmp.select_prev_item()
    end
    if forward and luasnip.expand_or_jumpable() then
      return luasnip.expand_or_jump()
    end
    if not forward and luasnip.jumpable(-1) then
      return luasnip.jump(-1)
    end
    fallback()
  end, { "i", "s" })
end

-- 3. el spec
return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
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

    apply_highlights()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = u.augroup("cmp.highlights"),
      desc = "Re-link cmp highlights after a colour scheme change",
      callback = apply_highlights,
    })

    cmp.setup({
      snippet = {
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      window = {
        completion = vim.tbl_extend("force", window, { side_padding = 1, scrollbar = false }),
        documentation = vim.tbl_extend("force", window, { max_width = 80, max_height = 20 }),
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(),
        ["<C-j>"] = cmp.mapping.select_next_item(),
        ["<C-p>"] = cmp.mapping.select_prev_item(),
        ["<C-n>"] = cmp.mapping.select_next_item(),
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = snippet_aware(cmp, luasnip, true),
        ["<S-Tab>"] = snippet_aware(cmp, luasnip, false),
      }),
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = format_item,
      },
      sources = cmp.config.sources(sources),
    })
  end,
}
