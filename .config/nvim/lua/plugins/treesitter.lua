--- Highlight, indent, folds y text objects con tree-sitter (rama main).
--- Requiere tree-sitter-cli (:MasonInstall tree-sitter-cli) para compilar parsers.
--- Selección incremental: la nativa de 0.12, `an` / `in` en visual.

local parsers = {
  "c",
  "cpp",
  "lua",
  "vim",
  "vimdoc",
  "bash",
  "php",
  "php_only",
  "javascript",
  "typescript",
  "tsx",
  "html",
  "css",
  "scss",
  "json",
  "yaml",
  "markdown",
  "markdown_inline",
  "sql",
  "dockerfile",
  "gitignore",
  "vue",
  "python",
}

local function textobject_keys()
  local select = require("nvim-treesitter-textobjects.select")
  local move = require("nvim-treesitter-textobjects.move")
  local swap = require("nvim-treesitter-textobjects.swap")
  local map = vim.keymap.set

  local objects = {
    f = { "function", "function" },
    c = { "class", "class" },
    a = { "parameter", "parameter" },
    i = { "conditional", "conditional" },
    l = { "loop", "loop" },
  }
  for key, obj in pairs(objects) do
    map({ "x", "o" }, "a" .. key, function()
      select.select_textobject("@" .. obj[1] .. ".outer", "textobjects")
    end, { desc = "a " .. obj[2] })
    map({ "x", "o" }, "i" .. key, function()
      select.select_textobject("@" .. obj[1] .. ".inner", "textobjects")
    end, { desc = "inner " .. obj[2] })
  end

  -- ]c queda para diff (gitsigns), por eso clases van en ]C.
  local moves = {
    f = { "@function.outer", "function" },
    C = { "@class.outer", "class" },
    a = { "@parameter.inner", "parameter" },
  }
  for key, m in pairs(moves) do
    map({ "n", "x", "o" }, "]" .. key, function()
      move.goto_next_start(m[1], "textobjects")
    end, { desc = "Next " .. m[2] })
    map({ "n", "x", "o" }, "[" .. key, function()
      move.goto_previous_start(m[1], "textobjects")
    end, { desc = "Previous " .. m[2] })
  end

  map("n", "<leader>sa", function()
    swap.swap_next("@parameter.inner")
  end, { desc = "Swap with next parameter" })
  map("n", "<leader>sA", function()
    swap.swap_previous("@parameter.inner")
  end, { desc = "Swap with previous parameter" })
end

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  dependencies = {
    { "nvim-treesitter/nvim-treesitter-textobjects", branch = "main" },
  },
  config = function()
    require("nvim-treesitter").install(parsers)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("config.treesitter", { clear = true }),
      callback = function(event)
        if not pcall(vim.treesitter.start, event.buf) then
          return
        end
        vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        local win = vim.fn.bufwinid(event.buf)
        if win ~= -1 then
          vim.wo[win][0].foldmethod = "expr"
          vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
        end
      end,
    })

    require("nvim-treesitter-textobjects").setup({
      select = { lookahead = true },
      move = { set_jumps = true },
    })
    textobject_keys()
  end,
}
