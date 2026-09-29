--- Fuzzy finding.
---
--- Native floor: `rg --files` (or `find`) piped into `vim.ui.select`, `:grep`
--- into the quickfix list, and the built-in buffer and oldfiles lists. No
--- fuzzy matching and no preview, but every entry point keeps working and
--- lands in the same place.
---
--- It also implements the `goto.*` features, so `gd` goes through Telescope
--- while this module is on and falls straight back to `vim.lsp.buf.definition`
--- when it is not. No `pcall(require, "telescope")` anywhere.
local function pick(items, prompt, on_choice)
  if #items == 0 then
    return vim.notify("nothing found", vim.log.levels.INFO)
  end
  vim.ui.select(items, { prompt = prompt }, function(choice)
    if choice then
      on_choice(choice)
    end
  end)
end

--- List project files without a plugin. ripgrep when available, find otherwise.
local function list_files(cwd, on_result)
  local cmd = vim.fn.executable("rg") == 1
      and { "rg", "--files", "--hidden", "--glob", "!.git" }
    or { "find", ".", "-type", "f", "-not", "-path", "*/.git/*" }
  vim.system(cmd, { text = true, cwd = cwd }, function(result)
    local files = vim.split(result.stdout or "", "\n", { trimempty = true })
    vim.schedule(function()
      on_result(files)
    end)
  end)
end

local function grep(pattern)
  if not pattern or pattern == "" then
    return
  end
  vim.cmd({ cmd = "grep", args = { vim.fn.shellescape(pattern) }, bang = true })
  if #vim.fn.getqflist() > 0 then
    vim.cmd.copen()
  else
    vim.notify("no matches", vim.log.levels.INFO)
  end
end

return {
  description = "Fuzzy finder",
  optional = { "editor.lsp" },

  native = function(ctx)
    ctx:reserve("<leader>f", "Find")

    ctx:declare("finder.files", {
      desc = "Find files in the project",
      native = function()
        return function()
          list_files(nil, function(files)
            pick(files, "Files", vim.cmd.edit)
          end)
        end
      end,
    })

    ctx:declare("finder.config", {
      desc = "Find files in the Neovim config",
      native = function()
        return function()
          local root = vim.fn.stdpath("config")
          list_files(root, function(files)
            pick(files, "Config", function(choice)
              vim.cmd.edit(vim.fs.joinpath(root, choice))
            end)
          end)
        end
      end,
    })

    ctx:declare("finder.grep", {
      desc = "Search text in the project",
      native = function()
        return function()
          vim.ui.input({ prompt = "Grep: " }, grep)
        end
      end,
    })

    ctx:declare("finder.word", {
      desc = "Search the word under the cursor",
      native = function()
        return function()
          grep(vim.fn.expand("<cword>"))
        end
      end,
    })

    ctx:declare("finder.buffers", {
      desc = "List open buffers",
      native = function()
        return function()
          local items = {}
          for _, buf in ipairs(vim.api.nvim_list_bufs()) do
            local name = vim.api.nvim_buf_get_name(buf)
            if vim.bo[buf].buflisted and name ~= "" and buf ~= vim.api.nvim_get_current_buf() then
              items[#items + 1] = vim.fn.fnamemodify(name, ":~:.")
            end
          end
          pick(items, "Buffers", vim.cmd.buffer)
        end
      end,
    })

    ctx:declare("finder.recent", {
      desc = "Recently opened files",
      native = function()
        return function()
          local items = {}
          for _, path in ipairs(vim.v.oldfiles) do
            if vim.uv.fs_stat(path) then
              items[#items + 1] = vim.fn.fnamemodify(path, ":~:.")
            end
            if #items >= 100 then
              break
            end
          end
          pick(items, "Recent", vim.cmd.edit)
        end
      end,
    })

    ctx:declare("finder.help", {
      desc = "Search the Neovim manual",
      native = function()
        return function()
          vim.ui.input({ prompt = "Help: ", completion = "help" }, function(topic)
            if topic and topic ~= "" then
              pcall(vim.cmd.help, topic)
            end
          end)
        end
      end,
    })

    ctx:slot("n", "<leader>ff", "finder.files")
    ctx:slot("n", "<leader>fg", "finder.grep")
    ctx:slot("n", "<leader>fw", "finder.word")
    ctx:slot("n", "<leader>fb", "finder.buffers")
    ctx:slot("n", "<leader>fr", "finder.recent")
    ctx:slot("n", "<leader>fh", "finder.help")
    ctx:slot("n", "<leader>fc", "finder.config")
    ctx:slot("n", "<leader>fd", "diagnostic.list")
    ctx:slot("n", "<leader>fs", "symbols.document")
  end,

  declare = function(ctx)
    local function builtin(name, opts)
      return function()
        return function()
          require("telescope.builtin")[name](opts)
        end
      end
    end

    ctx:implement("finder.files", 50, builtin("find_files"))
    ctx:implement("finder.grep", 50, builtin("live_grep"))
    ctx:implement("finder.word", 50, builtin("grep_string"))
    ctx:implement("finder.buffers", 50, builtin("buffers"))
    ctx:implement("finder.recent", 50, builtin("oldfiles"))
    ctx:implement("finder.help", 50, builtin("help_tags"))
    -- `<leader>/` is a core slot, because "search in this file" has a perfectly
    -- good native meaning. Telescope simply becomes the better implementation.
    ctx:implement("search.buffer", 50, builtin("current_buffer_fuzzy_find"))
    ctx:implement("finder.config", 50, function()
      return function()
        require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") })
      end
    end)

    -- Core's global slots keep their keys; only the implementation changes.
    ctx:implement("diagnostic.list", 50, builtin("diagnostics"))
    ctx:implement("symbols.document", 50, builtin("lsp_document_symbols"))
    ctx:implement("goto.definition", 50, builtin("lsp_definitions"))
    ctx:implement("goto.references", 50, builtin("lsp_references"))
    ctx:implement("goto.implementation", 50, builtin("lsp_implementations"))
    ctx:implement("goto.type_definition", 50, builtin("lsp_type_definitions"))
  end,

  plugins = function(ctx)
    return {
      {
        "nvim-telescope/telescope.nvim",
        branch = "0.1.x",
        -- No event or keys: the broker owns every mapping, and lazy.nvim hooks
        -- require(), so Telescope loads the first time a feature actually calls
        -- into it. Previously this spec had no trigger at all and loaded at
        -- startup, which made it the most expensive plugin in the config.
        lazy = true,
        cmd = "Telescope",
        dependencies = {
          "nvim-lua/plenary.nvim",
          {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function()
              return vim.fn.executable("make") == 1
            end,
          },
          "nvim-tree/nvim-web-devicons",
        },
      },
    }
  end,

  setup = function(ctx)
    local telescope = require("telescope")
    local actions = require("telescope.actions")

    telescope.setup({
      defaults = {
        prompt_prefix = ctx.ui.icons.ui.prompt,
        selection_caret = ctx.ui.icons.ui.selection,
        entry_prefix = ctx.ui.icons.ui.entry,
        path_display = { "truncate" },
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = { prompt_position = "top", preview_width = 0.55 },
        },
        file_ignore_patterns = {
          "node_modules/", "%.git/", "vendor/", "target/", "build/", "dist/", "%.lock$",
        },
        mappings = {
          i = {
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-j>"] = actions.move_selection_next,
            ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
            ["<Esc>"] = actions.close,
          },
        },
      },
      pickers = {
        find_files = { hidden = true, no_ignore = false },
        buffers = { sort_mru = true, ignore_current_buffer = true },
      },
    })

    pcall(telescope.load_extension, "fzf")
  end,
}
