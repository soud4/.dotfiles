return {
  {
    -- =========================================================================
    -- PLUGIN: nvim-cmp
    -- Motor de autocompletado rápido, modular y altamente personalizable.
    -- Inspirado en la arquitectura modular y estilo Atom/Cuadrado de NvChad UI.
    -- =========================================================================
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",         -- Fuente LSP (funciones, variables, tipos del lenguaje)
      "hrsh7th/cmp-buffer",           -- Fuente de palabras del buffer actual
      "hrsh7th/cmp-path",             -- Fuente de rutas de archivos del sistema
      "L3MON4D3/LuaSnip",             -- Motor de snippets
      "saadparwaiz1/cmp_luasnip",     -- Integración de LuaSnip con cmp
      "rafamadriz/friendly-snippets", -- Colección de snippets estilo VSCode
      "onsails/lspkind.nvim",         -- Utilidades para iconos
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      -- Cargar snippets estilo VSCode (friendly-snippets)
      require("luasnip.loaders.from_vscode").lazy_load()

      -- =======================================================================
      -- 1. DICCIONARIO DE ICONOS MODULARES (Inspirado en NvChad)
      -- =======================================================================
      local icons = {
        Namespace = "󰌗",
        Text = "󰉿",
        Method = "󰆧",
        Function = "󰆧",
        Constructor = "",
        Field = "󰜢",
        Variable = "󰀫",
        Class = "󰠱",
        Interface = "",
        Module = "",
        Property = "󰜢",
        Unit = "󰑭",
        Value = "󰎠",
        Enum = "",
        Keyword = "󰌋",
        Snippet = "",
        Color = "󱓻",
        File = "󰈚",
        Reference = "󰈇",
        Folder = "󰉋",
        EnumMember = "",
        Constant = "󰏿",
        Struct = "󰙅",
        Event = "",
        Operator = "󰆕",
        TypeParameter = "󰊄",
        Table = "",
        Object = "󰅩",
        Tag = "",
        Array = "[]",
        Boolean = "",
        Number = "",
        Null = "󰟢",
        String = "󰉿",
        Package = "",
        Copilot = "",
        Codeium = "",
      }

      -- =======================================================================
      -- 2. HIGHLIGHTS / COLORES PARA EL ESTADO CUADRADO (Atom Style)
      -- Define colores distintivos para cada tipo de ítem de autocompletado.
      -- =======================================================================
      local set_hl = vim.api.nvim_set_hl
      set_hl(0, "CmpItemKindFunction", { fg = "#7aa2f7", bold = true })
      set_hl(0, "CmpItemKindMethod", { fg = "#7aa2f7", bold = true })
      set_hl(0, "CmpItemKindVariable", { fg = "#e0af68" })
      set_hl(0, "CmpItemKindKeyword", { fg = "#bb9af7", bold = true })
      set_hl(0, "CmpItemKindSnippet", { fg = "#f7768e", bold = true })
      set_hl(0, "CmpItemKindClass", { fg = "#ff9e64" })
      set_hl(0, "CmpItemKindInterface", { fg = "#0db9d7" })
      set_hl(0, "CmpItemKindStruct", { fg = "#0db9d7" })
      set_hl(0, "CmpItemKindProperty", { fg = "#73daca" })
      set_hl(0, "CmpItemKindField", { fg = "#73daca" })
      set_hl(0, "CmpItemKindModule", { fg = "#ff9e64" })
      set_hl(0, "CmpItemKindFile", { fg = "#7aa2f7" })
      set_hl(0, "CmpItemKindFolder", { fg = "#e0af68" })
      set_hl(0, "CmpItemAbbrMatch", { fg = "#2ac3de", bold = true })
      set_hl(0, "CmpItemAbbrMatchFuzzy", { fg = "#2ac3de", underline = true })

      -- =======================================================================
      -- 3. CONFIGURACIÓN PRINCIPAL DE CMP
      -- =======================================================================
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },

        -- ---------------------------------------------------------------------
        -- VENTANAS FLOTANTES CUADRADAS (Square style sin bordes redondeados)
        -- ---------------------------------------------------------------------
        window = {
          -- Ventana de la lista de sugerencias
          completion = {
            border = "single", -- "single" crea un marco recto, fino y 100% cuadrado
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            side_padding = 1,  -- Espaciado compacto en los laterales
            scrollbar = false, -- Sin barra de scroll para un aspecto más limpio
          },
          -- Ventana de documentación de la función/variable
          documentation = {
            border = "single", -- Marco cuadrado recto a juego
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:PmenuSel,Search:None",
            max_width = 80,
            max_height = 20,
          },
        },

        -- ---------------------------------------------------------------------
        -- ATAJOS DE TECLADO (Mappings)
        -- ---------------------------------------------------------------------
        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.select_prev_item(), -- Ítem anterior
          ["<C-j>"] = cmp.mapping.select_next_item(), -- Ítem siguiente
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),     -- Scroll documentación arriba
          ["<C-f>"] = cmp.mapping.scroll_docs(4),      -- Scroll documentación abajo
          ["<C-Space>"] = cmp.mapping.complete(),      -- Forzar menú de autocompletado
          ["<C-e>"] = cmp.mapping.abort(),             -- Cerrar menú
          ["<CR>"] = cmp.mapping.confirm({ select = false }), -- Confirmar selección

          -- Navegación con Tab y Shift-Tab (compatible con snippets)
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

        -- ---------------------------------------------------------------------
        -- FORMATO VISUAL MODULAR (Inspirado en NvChad Atom/Square Style)
        -- Estructura: [ ICONO ] [ NOMBRE / PALABRA ] [ TIPO ~ ORIGEN ]
        -- ---------------------------------------------------------------------
        formatting = {
          -- Orden de las columnas: Ícono a la izquierda, texto en medio, detalle a la derecha
          fields = { "kind", "abbr", "menu" },

          format = function(entry, item)
            local icon = icons[item.kind] or "󰈚"
            local kind_label = item.kind or ""

            -- 1. Icono en bloque cuadrado a la izquierda
            item.kind = string.format(" %s ", icon)

            -- 2. Etiquetas del origen (Source)
            local source_names = {
              nvim_lsp = "LSP",
              luasnip = "Snippet",
              buffer = "Buffer",
              path = "Path",
            }
            local source_name = source_names[entry.source.name] or entry.source.name

            -- 3. Detalle derecho con máximo detalle: Tipo y Fuente (ej: "Function  [LSP]")
            item.menu = string.format("%-9s [%s]", kind_label, source_name)

            -- 4. Soporte para previsualización de colores CSS/Hexadecimales (#ff0000)
            if kind_label == "Color" and entry.completion_item.documentation then
              local doc = entry.completion_item.documentation
              if type(doc) == "string" and doc:match("^#%x%x%x%x%x%x$") then
                local hl_group = "HexColor_" .. doc:sub(2)
                vim.api.nvim_set_hl(0, hl_group, { fg = doc })
                item.kind = " 󱓻 "
                item.kind_hl_group = hl_group
              end
            end

            -- 5. Límite de ancho para no desbordar el menú
            local max_width = 38
            if #item.abbr > max_width then
              item.abbr = string.sub(item.abbr, 1, max_width) .. "…"
            end

            return item
          end,
        },

        -- ---------------------------------------------------------------------
        -- FUENTES DE AUTOCOMPLETADO Y PRIORIDADES
        -- ---------------------------------------------------------------------
        sources = cmp.config.sources({
          { name = "nvim_lsp", priority = 1000 }, -- LSP primero
          { name = "luasnip", priority = 750 },   -- Snippets
          { name = "path", priority = 500 },      -- Rutas de archivos
          { name = "buffer", priority = 250, keyword_length = 2 }, -- Texto en el buffer
        }),
      })
    end,
  },
}
