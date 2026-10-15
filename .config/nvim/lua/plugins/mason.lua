--- Installer for language servers and formatters.
return {
  "williamboman/mason.nvim",
  -- VeryLazy fires after the screen is drawn, so the cost stops being felt.
  -- The cmd list keeps :Mason working even if that event never arrives.
  event = "VeryLazy",
  cmd = {
    "Mason", "MasonInstall", "MasonUpdate",
    "MasonUninstall", "MasonUninstallAll", "MasonLog",
  },
  opts = {
    ui = {
      border = "single",
      icons = {
        package_installed = "✓",
        package_pending = "➜",
        package_uninstalled = "✗",
      },
    },
  },
}
