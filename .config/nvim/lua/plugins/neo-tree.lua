local function get_node_path(state)
  local node = state.tree:get_node()
  if not node then
    return nil
  end
  if node.type == "directory" then
    return node:get_id()
  end
  return vim.fs.dirname(node:get_id())
end

return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  lazy = false,
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons",
    "MunifTanjim/nui.nvim",
  },
  init = function()
    -- Desactiva netrw por completo antes de cargar el plugin
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
  end,
  keys = {
    { "<leader>e", "<cmd>Neotree toggle<CR>", desc = "Toggle file tree" },
    { "<leader>ge", "<cmd>Neotree git_status toggle<CR>", desc = "Toggle Git tree" },
    { "<leader>be", "<cmd>Neotree buffers toggle<CR>", desc = "Toggle Buffers tree" },
  },
  opts = {
    close_if_last_window = true,
    popup_border_style = "single",
    filesystem = {
      follow_current_file = {
        enabled = true,
      },
      use_libuv_file_watcher = true,
      filtered_items = {
        hide_dotfiles = false,
        hide_by_name = {
          ".git",
          "node_modules",
          ".next",
          "target",
          "vendor",
          "dist",
          "build",
        },
      },
    },
    window = {
      width = 30,
      mappings = {
        ["<space>"] = "none",
        ["l"] = "open",
        ["h"] = "close_node",
        ["P"] = { "toggle_preview", config = { use_float = true } },
        ["v"] = "open_vsplit",
        ["s"] = "open_split",
        ["F"] = function(state)
          local path = get_node_path(state)
          if path then
            require("telescope.builtin").find_files({ cwd = path })
          end
        end,
        ["G"] = function(state)
          local path = get_node_path(state)
          if path then
            require("telescope.builtin").live_grep({ cwd = path })
          end
        end,
        ["Y"] = function(state)
          local node = state.tree:get_node()
          if not node then
            return
          end
          local path = node:get_id()
          vim.fn.setreg("+", path)
          vim.notify("Ruta absoluta copiada: " .. path)
        end,
        ["y"] = function(state)
          local node = state.tree:get_node()
          if not node then
            return
          end
          local path = vim.fn.fnamemodify(node:get_id(), ":.")
          vim.fn.setreg("+", path)
          vim.notify("Ruta relativa copiada: " .. path)
        end,
      },
    },
  },
}
