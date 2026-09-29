--- Key hints.
---
--- Neither implementation keeps its own list of groups: both read the broker,
--- which already knows every namespace and every mapping with its description
--- and its owner. Disabling a module makes its group disappear from the hints
--- by itself — the stale `<leader>f` group left behind by a removed plugin is
--- not something that can happen here.
---
--- Native floor: the same information in a floating window, on demand.
return {
  description = "Key hints",

  native = function(ctx)
    ctx:reserve("<leader>?", "Key hints")

    ctx:declare("hints.show", {
      desc = "Show available keys",
      native = function()
        return function()
          vim.ui.input({ prompt = "Prefix (empty for all): " }, function(prefix)
            if prefix == nil then
              return
            end
            local lines = {}
            for _, group in ipairs(ctx:groups()) do
              if prefix == "" or group.prefix:sub(1, #prefix) == prefix then
                lines[#lines + 1] = ("  %-14s %-26s %s"):format(group.prefix, group.desc, group.owner)
              end
            end
            if #lines > 0 then
              table.insert(lines, 1, "namespaces")
              lines[#lines + 1] = ""
            end
            lines[#lines + 1] = "mappings"
            for _, map in ipairs(ctx:mappings(prefix ~= "" and prefix or nil)) do
              lines[#lines + 1] = ("  %-3s %-16s %-34s %s"):format(map.mode, map.lhs, map.desc or "", map.owner)
            end
            require("dohwa.popup").show(lines, { title = "keys" })
          end)
        end
      end,
    })

    ctx:slot("n", "<leader>??", "hints.show")
  end,

  declare = function(ctx)
    ctx:implement("hints.show", 50, function()
      return function()
        require("which-key").show({ global = false })
      end
    end)
  end,

  plugins = function(ctx)
    -- Group names are derived from the broker's reservations rather than
    -- written out again here.
    local spec = {}
    for _, group in ipairs(ctx:groups(true)) do
      spec[#spec + 1] = { group.prefix, group = group.desc }
    end

    return {
      {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
          preset = "helix", -- compact side panel rather than the full screen
          delay = 500, -- long enough to stay out of the way when you know the key
          icons = { mappings = false },
          win = { border = ctx.ui.border },
          spec = spec,
        },
      },
    }
  end,
}
