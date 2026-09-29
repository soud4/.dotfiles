--- Core plus a theme, nothing else. `DOHWA_PROFILE=minimal nvim`.
---
--- Useful to see what the editor is when almost everything is off, and to
--- check that the protected core stands on its own.
return {
  default = false,
  loader = "lazy",
  modules = {
    ["core.options"] = true,
    ["core.keys"] = true,
    ["core.autocmds"] = true,
    ["core.toggles"] = true,
    ["ui.theme"] = true,
  },
}
