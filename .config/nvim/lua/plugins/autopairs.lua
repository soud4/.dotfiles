--- Automatic pairs.

-- 1. datos
local opts = {
  check_ts = true, -- use tree-sitter to judge the syntactic context
  ts_config = {
    lua = { "string" }, -- no automatic pairs inside Lua strings
    javascript = { "template_string" },
    java = false,
  },
  -- <CR> belongs to nvim-cmp. Letting both map it is a real collision:
  -- confirming a completion would also insert a newline.
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

-- 2. helpers

--- Agrega los parentesis despues de completar una funcion. Silencioso si cmp
--- no esta cargado: no es una dependencia dura.
local function hook_cmp()
  local ok, cmp = pcall(require, "cmp")
  if ok then
    cmp.event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())
  end
end

-- 3. el spec
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  -- Ordering only: the confirm_done hook needs cmp already loaded, and both
  -- plugins trigger on the same event.
  dependencies = { "hrsh7th/nvim-cmp" },
  config = function()
    require("nvim-autopairs").setup(opts)
    hook_cmp()
  end,
}
