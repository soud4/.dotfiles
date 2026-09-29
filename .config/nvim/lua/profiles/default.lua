--- The everyday profile.
---
--- `default = true` means a module file that is not listed here is on, so
--- dropping a new file into `lua/modules/` just works. List a module with
--- `false` to switch it off; `:Dohwa disable <module>` writes the same decision
--- into the state file without touching this one.
return {
  default = true,
  loader = "lazy",
  modules = {},
}
