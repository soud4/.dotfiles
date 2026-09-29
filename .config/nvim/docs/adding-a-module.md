# Adding a module

Every plugin in this configuration is a module, and so is everything that is not
a plugin. This is the procedure for adding one without breaking the three rules
the design rests on: a native fallback for everything, no key collisions between
modules, and no module referencing another.

A module is `lua/modules/<group>/<name>.lua`. Its path is its name, so
`tools/git.lua` is `tools.git`. There is no index to update and nothing to
register: dropping the file in is the registration, and the profile switches it
on by default.

## Step 0: classify the plugin

Three questions, and the answers decide how many hooks you write.

| Question | If no | If yes |
|---|---|---|
| Does it come with keys? | `plugins` only | + `reserve` and `slot`/`map` in `native` |
| Can Neovim already do something similar? | no Feature | + `declare` a Feature with a `native` |
| Does it replace or feed another module? | — | + `implement`/`value` on an existing Feature |

The second question is the one that matters, and the answer is more often yes
than people expect. Before assuming there is no native floor, check: `gc`/`gcc`
for comments (built in since 0.10), netrw for browsing files, `vim.ui.open`,
`vim.ui.select`, `vim.snippet`, `vim.lsp.*`, `vim.treesitter.*`, `:grep` into the
quickfix list, `'formatprg'`.

## The four hooks

```lua
return {
  description = "One line",
  requires = {},   -- hard: a missing one disables this module, transitively
  optional = {},   -- soft: ordering only, never disables anything

  -- ALWAYS, while the module is active, including under DOHWA_LOADER=null.
  -- Declares Features with their native implementation, reserves the key
  -- namespace, binds keys.
  native = function(ctx) end,

  -- ONLY when the plugins will actually be installed. Registers the better
  -- implementations, as thunks. Never require() a plugin here.
  declare = function(ctx) end,

  -- Pure data for the loader.
  plugins = function(ctx) return { { "owner/repo", event = "..." } } end,

  -- Runs inside the plugin's own config(), so it stays lazy.
  setup = function(ctx) end,
}
```

The split between `native` and `declare` is what makes switching a module off
safe. With the null loader, or when a module is skipped because a hard
dependency is missing, `declare` and `setup` never run and every Feature stays
on its priority-0 implementation.

## Case A: the plugin just works

No keys, no capability anyone else cares about. `folke/ts-comments.nvim` only
improves the `commentstring` that the built-in `gc` already uses, so the native
floor is Neovim itself and there is nothing to declare.

`lua/modules/editor/comments.lua`:

```lua
--- Better commentstring for embedded languages.
---
--- Native floor: Neovim's own gc/gcc, built in since 0.10. This module only
--- teaches it about embedded languages, so switching it off costs accuracy in
--- JSX and Vue, not the ability to comment.
return {
  description = "Comment string via tree-sitter",
  optional = { "editor.syntax" },

  plugins = function()
    return {
      {
        "folke/ts-comments.nvim",
        event = "VeryLazy",
        opts = {},
      },
    }
  end,
}
```

That is the whole module. No `native`, no `declare`, no `setup`.

## Case B: it has a key and a native equivalent

`stevearc/oil.nvim` is a file explorer, and Neovim ships netrw.

`lua/modules/tools/explorer.lua`:

```lua
--- File explorer.
---
--- Native floor: netrw, which ships with Neovim. <leader>e opens whichever
--- explorer is in charge, so disabling this module changes which one appears
--- and nothing else.
return {
  description = "File explorer",

  native = function(ctx)
    ctx:declare("explorer.open", {
      desc = "Open the file explorer",
      native = function()
        return function()
          vim.cmd.Explore()
        end
      end,
    })

    ctx:reserve("<leader>e", "Explorer")
    ctx:slot("n", "<leader>e", "explorer.open")
  end,

  declare = function(ctx)
    ctx:implement("explorer.open", 50, function()
      return function()
        require("oil").open()
      end
    end)
  end,

  plugins = function()
    return {
      {
        "stevearc/oil.nvim",
        -- No trigger: the broker owns the key, and lazy.nvim hooks require(),
        -- so oil loads the first time the feature is actually called.
        lazy = true,
        opts = { view_options = { show_hidden = true } },
        dependencies = { "nvim-tree/nvim-web-devicons" },
      },
    }
  end,
}
```

Note what is absent: no `pcall(require, "oil")`, no `if has_oil then`, and no
load trigger. What it buys:

- `DOHWA_LOADER=null nvim` — `<leader>e` opens netrw.
- `:Dohwa disable tools.explorer` — the key disappears, nothing else changes.
- `:checkhealth dohwa` — `explorer.open  tools.explorer:50 (over tools.explorer:0)`.

### Single-character global keys

`oil.nvim` uses `-` by convention. A one-character reservation in a specific
mode is legitimate — `editor.pairs` does exactly this with `(` in insert mode:

```lua
ctx:reserve("-", "Explorer", { modes = { "n" } })
ctx:slot("n", "-", "explorer.open")
```

Any other module asking for `-` in normal mode is then refused by name.

## Case C: it feeds or replaces another module

Never with `require`. Always through Features, in both directions:

```lua
-- CONSUME whatever another module publishes, with a fallback when it is off:
local capabilities = ctx:value("lsp.capabilities", vim.lsp.protocol.make_client_capabilities())

-- PUBLISH for whoever wants it, without knowing who:
ctx:implement("git.diffstat", 50, function()
  return function()
    return { added = 3, changed = 1, removed = 0 }
  end
end)

-- TAKE OVER a state feature this plugin handles from its own setup():
ctx:override("syntax.engine")
```

Implementing a Feature nobody declared creates an optional placeholder and flags
it: `:checkhealth dohwa` lists it under *implemented but never declared*, which
is what a misspelled name looks like. If the declaring module is simply off,
nothing else happens.

## Five things that trip you up

1. **If you define `setup`, do not pass `opts`.** That module now owns its main
   spec's `config()`, so lazy.nvim no longer applies `opts` for you. Keep the
   table in a local and pass it yourself — see `OPTS` in
   `lua/modules/editor/pairs.lua`.
2. **`dohwa_main = true`** on the spec that should carry the `config()`, when it
   is not the first in the list. `lua/modules/editor/lsp.lua` uses it.
3. **Never `require()` a plugin in `native` or `declare`.** Only inside the thunk
   that returns the implementation, or in `setup`. This is what preserves lazy
   loading.
4. **Mappings the plugin installs itself** go through
   `ctx:external(modes, lhs, desc)`. They are not applied, but they take part in
   collision detection and show up in `:Dohwa keys`. Without this they are
   invisible — the gap that nvim-treesitter-textobjects and gitsigns had.
5. **Shared namespaces hand out one letter per module:** `ctx:toggle(letter, ...)`
   for `<leader>t`, `ctx:jump(letter, ...)` for `]`/`[`,
   `ctx:textobject(letter, ...)` for `a`/`i`. A second taker is refused, naming
   both modules.

## The Context API

Everything a module may touch, all tagged with its name so ownership is never
ambiguous. Defined in `lua/dohwa/context.lua`.

| Method | Purpose |
|---|---|
| `ctx:declare(name, opts)` | declare a Feature; `opts.native` is the priority-0 floor |
| `ctx:implement(name, priority, provider)` | register a better implementation, as a thunk |
| `ctx:override(name)` | suppress the native floor because the plugin handles it |
| `ctx:call(name, ...)` / `ctx:value(name, default)` | use a Feature |
| `ctx:reserve(prefix, desc, opts)` | claim a key namespace; `opts.modes` narrows it |
| `ctx:map(modes, lhs, rhs, opts)` | map inside your namespace |
| `ctx:slot(modes, lhs, feature, opts)` | bind a key to a Feature |
| `ctx:toggle` / `ctx:jump` / `ctx:textobject` | take a letter in a shared namespace |
| `ctx:external(modes, lhs, desc)` | declare a mapping the plugin installs itself |
| `ctx:augroup(suffix)` / `ctx:autocmd(event, opts)` | namespaced autocommands |
| `ctx:opt(table)` | set options |
| `ctx:has(module)` | is another module active |
| `ctx.ui` | shared visual tokens from `lua/core/ui.lua` |

## Removing a plugin

```
:Dohwa disable tools.explorer       # persisted in the state file, reversible
rm lua/modules/tools/explorer.lua   # permanent
nvim --headless "+Lazy! clean" +qa
```

Either way the Feature returns to its native implementation and the module's
keys are released, with re-arbitration: a prefix that just came free becomes
available to whoever else wanted it.

## Verifying

After adding any module, in this order:

```bash
nvim --headless "+Lazy! sync" +qa          # install
nvim --headless "+checkhealth dohwa" +qa   # 0 rejected, 0 shadowed, 0 orphan features
./scripts/matrix.sh lazy                   # disable each module in turn
./scripts/matrix.sh null                   # and again with no plugins at all
DOHWA_LOADER=null nvim                     # the native path by hand: still usable?
```

What to look for in `:checkhealth dohwa`: the new Feature showing
`module:50 (over module:0)`, the new namespace in the count, and
`no rejected mappings` still intact. If the matrix fails when your new module is
disabled, one of its Features is missing its native implementation.
