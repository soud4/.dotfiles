--- Syntax highlighting, indentation and structural text objects.

-- 1. datos: todo lo que configs.setup() recibe tal cual.
local settings = {
  ensure_installed = {
    "c", "cpp", "lua", "vim", "vimdoc", "bash", "php", "php_only",
    "javascript", "typescript", "tsx", "html", "css", "scss", "json",
    "yaml", "markdown", "markdown_inline", "sql", "dockerfile", "gitignore",
    "vue",
  },
  auto_install = true,
  highlight = { enable = true, additional_vim_regex_highlighting = false },
  indent = { enable = true },
  incremental_selection = {
    enable = true,
    keymaps = {
      init_selection = "<C-space>",
      node_incremental = "<C-space>",
      scope_incremental = false,
      node_decremental = "<bs>",
    },
  },
  textobjects = {
    select = {
      enable = true,
      lookahead = true, -- jump to the next object when outside one
      keymaps = {
        ["af"] = { query = "@function.outer", desc = "a function" },
        ["if"] = { query = "@function.inner", desc = "inner function" },
        ["ac"] = { query = "@class.outer", desc = "a class" },
        ["ic"] = { query = "@class.inner", desc = "inner class" },
        ["aa"] = { query = "@parameter.outer", desc = "a parameter" },
        ["ia"] = { query = "@parameter.inner", desc = "inner parameter" },
        ["ai"] = { query = "@conditional.outer", desc = "a conditional" },
        ["ii"] = { query = "@conditional.inner", desc = "inner conditional" },
        ["al"] = { query = "@loop.outer", desc = "a loop" },
        ["il"] = { query = "@loop.inner", desc = "inner loop" },
      },
    },
    move = {
      enable = true,
      set_jumps = true,
      goto_next_start = {
        ["]f"] = { query = "@function.outer", desc = "Next function" },
        -- ]c stays the built-in diff motion, which gitsigns relies on.
        ["]C"] = { query = "@class.outer", desc = "Next class" },
        ["]a"] = { query = "@parameter.inner", desc = "Next parameter" },
      },
      goto_previous_start = {
        ["[f"] = { query = "@function.outer", desc = "Previous function" },
        ["[C"] = { query = "@class.outer", desc = "Previous class" },
        ["[a"] = { query = "@parameter.inner", desc = "Previous parameter" },
      },
    },
    swap = {
      enable = true,
      swap_next = { ["<leader>sa"] = { query = "@parameter.inner", desc = "Swap with next parameter" } },
      swap_previous = { ["<leader>sA"] = { query = "@parameter.inner", desc = "Swap with previous parameter" } },
    },
  },
}

-- 2. helpers

local function unwrap(node)
  return type(node) == "table" and node[1] or node
end

--- Neovim 0.12 dropped directives the master branch of nvim-treesitter still
--- emits; re-register them so markdown injections keep working.
local function register_directives()
  local query = vim.treesitter.query

  query.add_directive("set-lang-from-info-string!", function(match, _, bufnr, pred, metadata)
    local node = unwrap(match[pred[2]])
    if not node then
      return
    end
    local alias = vim.treesitter.get_node_text(node, bufnr):lower():match("^%s*([%w_%-]+)")
    if not alias then
      return
    end
    metadata["injection.language"] = vim.filetype.match({ filename = "a." .. alias }) or alias
  end, { force = true, all = true })

  query.add_directive("downcase!", function(match, _, bufnr, pred, metadata)
    local id = pred[2]
    local node = unwrap(match[id])
    if not node then
      return
    end
    local text = vim.treesitter.get_node_text(node, bufnr, { metadata = metadata[id] }) or ""
    metadata[id] = metadata[id] or {}
    metadata[id].text = text:lower()
  end, { force = true, all = true })
end

--- `auto_install` compiles a parser from the FileType event. A handful of
--- grammars (latex, swift, teal, ...) must first be regenerated with the
--- tree-sitter CLI; when that binary is not on PATH the installer aborts with
--- an error raised inside the autocommand, which Neovim reports as "Error in
--- BufReadPost Autocommands". Opt those grammars out instead, so the buffer
--- just falls back to regex syntax.
local function grammars_needing_cli()
  if vim.fn.executable("tree-sitter") == 1 then
    return {}
  end
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok or not parsers.get_parser_configs then
    return {}
  end
  local out = {}
  for lang, info in pairs(parsers.get_parser_configs()) do
    if info.install_info and info.install_info.requires_generate_from_grammar then
      out[#out + 1] = lang
    end
  end
  return out
end

--- El modulo de configuracion cambio de nombre entre ramas.
local function configs()
  local ok, mod = pcall(require, "nvim-treesitter.configs")
  return ok and mod or require("nvim-treesitter.config")
end

-- 3. el spec
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
  },
  config = function()
    register_directives()
    settings.ignore_install = grammars_needing_cli()
    configs().setup(settings)
  end,
}
