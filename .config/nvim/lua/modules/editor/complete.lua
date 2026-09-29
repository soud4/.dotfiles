--- Completion and snippets.
---
--- Native floor, and it is a real one on 0.12: `vim.lsp.completion.enable()`
--- with autotrigger drives the built-in popup menu from the language server,
--- `completeopt` (set in core.options) gives it fuzzy matching and a doc
--- popup, and `vim.snippet` expands and navigates server snippets. Switching
--- this module off costs the extra sources and the icons, not completion.
---
--- It also publishes `lsp.capabilities`, which editor.lsp reads through the
--- registry instead of calling `require("cmp_nvim_lsp")` directly. That single
--- indirection is what lets the LSP survive this module being disabled.
return {
  description = "Completion and snippets",

  native = function(ctx)
    ctx:declare("completion.engine", {
      kind = "state",
      desc = "Completion engine",
      native = function()
        return function()
          ctx:autocmd("LspAttach", {
            group = ctx:augroup("native"),
            desc = "Built-in LSP completion with autotrigger",
            callback = function(args)
              local client = vim.lsp.get_client_by_id(args.data.client_id)
              if client and client:supports_method("textDocument/completion") then
                vim.lsp.completion.enable(true, args.data.client_id, args.buf, { autotrigger = true })
              end
            end,
          })
        end
      end,
    })
  end,

  declare = function(ctx)
    ctx:implement("lsp.capabilities", 50, function()
      return require("cmp_nvim_lsp").default_capabilities()
    end)

    -- nvim-cmp installs its own mappings and popup from setup().
    ctx:override("completion.engine")

    -- <Tab> is deliberately left alone. cmp installs its own keymap layer over
    -- whatever <Tab> was already bound to, and calls that as its fallback, so
    -- the core slot ends up as the last link in the chain: cmp menu, then
    -- LuaSnip, then the native pum/vim.snippet handling, then a literal tab.
    -- Implementing completion.next here would replace that final link with
    -- cmp.select_next_item(), and a plain tab would vanish.

    -- Mappings nvim-cmp installs itself, declared so they are still checked
    -- against everything else and listed by :Dohwa keys.
    for lhs, desc in pairs({
      ["<CR>"] = "Confirm completion",
      ["<C-Space>"] = "Trigger completion",
      ["<C-e>"] = "Dismiss completion",
      ["<C-b>"] = "Scroll docs up",
      ["<C-f>"] = "Scroll docs down",
      ["<C-n>"] = "Next item",
      ["<C-p>"] = "Previous item",
    }) do
      ctx:external("i", lhs, desc)
    end
  end,

  plugins = function(ctx)
    return {
      {
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
      },
    }
  end,

  setup = function(ctx)
    local cmp = require("cmp")
    local luasnip = require("luasnip")
    require("luasnip.loaders.from_vscode").lazy_load()

    local icons = ctx.ui.icons.kinds

    -- Link the menu to tree-sitter groups rather than hard-coding colours, so
    -- it follows whatever colour scheme ui.theme ends up applying.
    local function apply_highlights()
      local links = {
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
      for from, to in pairs(links) do
        vim.api.nvim_set_hl(0, from, { link = to, default = false })
      end
    end
    apply_highlights()
    ctx:autocmd("ColorScheme", {
      group = ctx:augroup("highlights"),
      desc = "Re-link cmp highlights after a colour scheme change",
      callback = apply_highlights,
    })

    local window = {
      border = ctx.ui.border,
      winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
    }

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
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, item)
          local kind = item.kind or ""
          item.kind = (" %s "):format(icons[kind] or icons.File)

          local sources = { nvim_lsp = "LSP", luasnip = "Snippet", buffer = "Buffer", path = "Path" }
          item.menu = ("%-9s [%s]"):format(kind, sources[entry.source.name] or entry.source.name)

          -- Preview CSS/hex colours in the kind column.
          if kind == "Color" and entry.completion_item.documentation then
            local doc = entry.completion_item.documentation
            if type(doc) == "string" and doc:match("^#%x%x%x%x%x%x$") then
              local group = "HexColor_" .. doc:sub(2)
              vim.api.nvim_set_hl(0, group, { fg = doc })
              item.kind = " " .. icons.Color .. " "
              item.kind_hl_group = group
            end
          end

          local max_width = 38
          if #item.abbr > max_width then
            item.abbr = item.abbr:sub(1, max_width) .. "…"
          end
          return item
        end,
      },
      sources = cmp.config.sources({
        { name = "nvim_lsp", priority = 1000 },
        { name = "luasnip", priority = 750 },
        { name = "path", priority = 500 },
        { name = "buffer", priority = 250, keyword_length = 2 },
      }),
    })
  end,
}
