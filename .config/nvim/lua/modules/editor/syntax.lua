--- Syntax highlighting, indentation and structural text objects.
---
--- Native floor: Neovim 0.12 bundles `vim.treesitter.start()` and parsers for
--- c, lua, markdown, markdown_inline, query, vim and vimdoc. Files with a
--- bundled parser get real tree-sitter highlighting with no plugin at all;
--- everything else falls back to the regex syntax engine.
return {
  description = "Syntax, indentation and text objects",

  native = function(ctx)
    ctx:declare("syntax.engine", {
      kind = "state",
      desc = "Syntax highlighting engine",
      native = function()
        return function()
          ctx:autocmd("FileType", {
            group = ctx:augroup("highlight"),
            desc = "Tree-sitter where a parser exists, regex otherwise",
            callback = function(args)
              if not pcall(vim.treesitter.start, args.buf) then
                vim.bo[args.buf].syntax = "ON"
              end
            end,
          })
        end
      end,
    })

    ctx:reserve("<leader>s", "Swap (tree-sitter)")
  end,

  declare = function(ctx)
    -- nvim-treesitter installs its own FileType handling from setup(), so the
    -- native autocommand must not also run. A no-op at higher priority is how a
    -- module says "I am taking this over".
    ctx:override("syntax.engine")

    -- Mappings nvim-treesitter-textobjects installs itself. Declaring them here
    -- does not apply them; it puts them in front of the collision checker and
    -- into `:Dohwa keys`, which is the only reason plugin-internal mappings are
    -- otherwise invisible.
    for letter, desc in pairs({
      f = "function",
      c = "class",
      a = "parameter",
      i = "conditional",
      l = "loop",
    }) do
      ctx:textobject(letter, desc, { external = true })
    end
    for letter, desc in pairs({ f = "function", C = "class", a = "parameter" }) do
      ctx:jump(letter, desc, { external = true })
    end
    ctx:external({ "n", "x" }, "<C-space>", "Expand syntactic selection")
    ctx:external("x", "<BS>", "Shrink syntactic selection")
    ctx:external("n", "<leader>sa", "Swap with next parameter")
    ctx:external("n", "<leader>sA", "Swap with previous parameter")
  end,

  plugins = function()
    return {
      {
        "nvim-treesitter/nvim-treesitter",
        branch = "master",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        dependencies = {
          { "nvim-treesitter/nvim-treesitter-textobjects", branch = "master" },
        },
      },
    }
  end,

  setup = function(ctx)
    -- Neovim 0.12 dropped directives the master branch of nvim-treesitter still
    -- emits; re-register them so markdown injections keep working.
    local query = vim.treesitter.query
    local function unwrap(node)
      return type(node) == "table" and node[1] or node
    end

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

    local ok, configs = pcall(require, "nvim-treesitter.configs")
    if not ok then
      configs = require("nvim-treesitter.config")
    end

    -- `auto_install` compiles a parser from the FileType event. A handful of
    -- grammars (latex, swift, teal, ...) must first be regenerated with the
    -- tree-sitter CLI; when that binary is not on PATH the installer aborts
    -- with an error raised inside the autocommand, which Neovim reports as
    -- "Error in BufReadPost Autocommands". Opt those grammars out instead, so
    -- the buffer just falls back to regex syntax.
    local ignore_install = {}
    if vim.fn.executable("tree-sitter") ~= 1 then
      local ok_parsers, parsers = pcall(require, "nvim-treesitter.parsers")
      if ok_parsers and parsers.get_parser_configs then
        for lang, info in pairs(parsers.get_parser_configs()) do
          if info.install_info and info.install_info.requires_generate_from_grammar then
            table.insert(ignore_install, lang)
          end
        end
      end
    end

    configs.setup({
      ignore_install = ignore_install,
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
    })
  end,
}
