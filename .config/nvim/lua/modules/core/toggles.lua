--- The shared `<leader>t` namespace.
---
--- Modules do not map toggle keys themselves; they ask for a letter. The broker
--- refuses a letter that is already taken and names both modules, so two
--- modules can never quietly land on the same toggle.
return {
  description = "Toggle namespace",

  native = function(ctx)
    ctx:reserve("<leader>t", "Toggles", { toggles = true })

    ctx:toggle("w", "Toggle: line wrap", function()
      vim.wo.wrap = not vim.wo.wrap
      vim.notify("wrap: " .. (vim.wo.wrap and "on" or "off"))
    end)

    ctx:toggle("d", "Toggle: diagnostics", function()
      local enabled = vim.diagnostic.is_enabled()
      vim.diagnostic.enable(not enabled)
      vim.notify("diagnostics: " .. (enabled and "off" or "on"))
    end)

    ctx:toggle("n", "Toggle: relative numbers", function()
      vim.wo.relativenumber = not vim.wo.relativenumber
      vim.notify("relativenumber: " .. (vim.wo.relativenumber and "on" or "off"))
    end)

    ctx:toggle("s", "Toggle: spell check", function()
      vim.wo.spell = not vim.wo.spell
      vim.notify("spell: " .. (vim.wo.spell and "on" or "off"))
    end)
  end,
}
