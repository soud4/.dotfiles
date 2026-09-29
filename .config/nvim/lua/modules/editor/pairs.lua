--- Automatic bracket and quote closing.
---
--- The keys involved are single characters in insert mode, so this module
--- reserves exactly those characters in exactly that mode. The namespace rule
--- then applies as it does anywhere else: nothing else can map `(` in insert
--- without being refused by name.
---
--- Native floor: plain `<expr>` mappings. No tree-sitter context awareness and
--- no fast-wrap, but brackets and quotes still close themselves.
local PAIRS = {
  ["("] = ")",
  ["["] = "]",
  ["{"] = "}",
}

local QUOTES = { '"', "'", "`" }

--- Kept here rather than in the plugin spec: a module that defines setup()
--- owns its main spec's config(), so lazy.nvim's implicit opts handling no
--- longer applies and the table is passed explicitly.
local OPTS = {
  check_ts = true, -- use tree-sitter to judge the syntactic context
  ts_config = {
    lua = { "string" }, -- no automatic pairs inside Lua strings
    javascript = { "template_string" },
    java = false,
  },
  -- <CR> stays with the completion engine. Letting both map it is the kind of
  -- overlap this config exists to avoid.
  map_cr = false,
  disable_filetype = { "TelescopePrompt", "spectre_panel", "guihua" },
  fast_wrap = {
    map = "<M-e>",
    chars = { "{", "[", "(", '"', "'" },
    pattern = [=[[%'%"%>%]%)%}%,]]=],
    end_key = "$",
    keys = "qwertyuiopzxcvbnmasdfghjkl",
    check_comma = true,
    highlight = "Search",
    highlight_grey = "Comment",
  },
}

local function next_char()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(col + 1, col + 1)
end

local function prev_char()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  return line:sub(col, col)
end

return {
  description = "Automatic pairs",
  optional = { "editor.complete", "editor.syntax" },

  native = function(ctx)
    for open, close in pairs(PAIRS) do
      ctx:reserve(open, "Auto pair", { modes = { "i" } })
      ctx:reserve(close, "Auto pair", { modes = { "i" } })

      ctx:map("i", open, function()
        return open .. close .. "<Left>"
      end, { expr = true, desc = "Insert " .. open .. close })

      -- Typing the closing character where one already sits just steps over it.
      ctx:map("i", close, function()
        return next_char() == close and "<Right>" or close
      end, { expr = true, desc = "Close or step over " .. close })
    end

    for _, quote in ipairs(QUOTES) do
      ctx:reserve(quote, "Auto pair", { modes = { "i" } })
      ctx:map("i", quote, function()
        if next_char() == quote then
          return "<Right>"
        end
        -- Do not pair inside a word: an apostrophe in "don't" is not an opener.
        if prev_char():match("[%w_]") then
          return quote
        end
        return quote .. quote .. "<Left>"
      end, { expr = true, desc = "Insert a pair of " .. quote })
    end

    ctx:reserve("<BS>", "Auto pair", { modes = { "i" } })
    ctx:map("i", "<BS>", function()
      local before, after = prev_char(), next_char()
      if PAIRS[before] == after or (vim.tbl_contains(QUOTES, before) and before == after) then
        return "<BS><Del>"
      end
      return "<BS>"
    end, { expr = true, desc = "Delete both halves of a pair" })

    ctx:opt({ showmatch = true })
  end,

  declare = function(ctx)
    -- nvim-autopairs installs its own mappings for exactly these keys, so the
    -- native ones must go. Releasing the module's own claims and re-declaring
    -- them as external keeps them visible without applying them twice.
    ctx:revoke_keys()
    for key in pairs(PAIRS) do
      ctx:reserve(key, "Auto pair (plugin)", { modes = { "i" } })
      ctx:external("i", key, "Insert a pair")
    end
    for _, close in pairs(PAIRS) do
      ctx:reserve(close, "Auto pair (plugin)", { modes = { "i" } })
      ctx:external("i", close, "Close or step over")
    end
    for _, quote in ipairs(QUOTES) do
      ctx:reserve(quote, "Auto pair (plugin)", { modes = { "i" } })
      ctx:external("i", quote, "Insert a pair")
    end
    ctx:external("i", "<BS>", "Delete both halves of a pair")
    ctx:external("i", "<M-e>", "Fast wrap")
  end,

  plugins = function()
    return {
      {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
      },
    }
  end,

  setup = function(ctx)
    require("nvim-autopairs").setup(OPTS)

    -- Add the parentheses after completing a function, when both modules are on.
    if ctx:has("editor.complete") then
      local ok, cmp = pcall(require, "cmp")
      if ok then
        cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
      end
    end
  end,
}
