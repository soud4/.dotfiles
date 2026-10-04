# Dohwa

A Neovim configuration built around one master object. Everything else —
options, mappings, autocommands, the plugin loader — is a module registered
into it.

Three rules hold the thing together:

1. **Every module has a native fallback.** Switching a module off, or running
   with no plugin manager at all, leaves a working editor.
2. **No module can collide with another on a key.** Namespaces are exclusive,
   global keys belong to the core, and the whole key model is validated before
   a single mapping is set.
3. **Modules never reference each other.** They meet through named features,
   never through `require("some-plugin")`.

```
init.lua                 leader keys, then require("dohwa"):boot()
lua/core/ui.lua          shared visual tokens (border, icons)
lua/dohwa/               the kernel
lua/modules/             one file per switchable unit
lua/profiles/            which modules are on
docs/                    the documentation, read from inside nvim
scripts/matrix.sh        the disable matrix
scripts/gendoc.sh        the generated reference pages
```

**[docs/README.md](docs/README.md)** is the map: architecture, one page per
module group, the task guides, and a generated key and feature reference.
`<leader>hh` browses it inside Neovim, `<leader>hm` opens the page for the file
you are editing.

## The object model

```
Object                   new() · extend() · is_a()
├── Dohwa                the master object: modules, graph, registry, broker, boot
├── Module               lifecycle of one unit
│   ├── CoreModule       protected; anything under modules/core/
│   └── PluginModule     contributes specs to the loader
├── Loader               interface
│   ├── LazyLoader       lazy.nvim
│   └── NullLoader       no plugins at all
├── Feature              a capability with implementations ranked by priority
├── FeatureRegistry      every feature in the system
├── KeyBroker            key ownership and arbitration
│   └── KeyTrie          duplicate and prefix-shadow detection
├── Graph                topological sort, cycles, reverse dependencies
├── Profile              what is on, and where that is remembered
└── Context              the handle a module receives (`ctx`)
```

Modules themselves are plain declarative tables, not classes. They are
singletons; instantiating them would buy nothing and would let them hide state
that breaks lazy loading.

## Features

A feature is a named capability with several implementations. Priority 0 is the
native floor, declared by whoever owns the concept, and it is never removed.
Modules register better implementations above it.

```lua
-- modules/core/keys.lua — declares the concept and the native floor
ctx:declare("goto.definition", { desc = "Go to definition", native = ... })
ctx:slot("n", "gd", "goto.definition")

-- modules/tools/finder.lua — competes, without ever naming a key
ctx:implement("goto.definition", 50, function()
  return require("telescope.builtin").lsp_definitions
end)
```

Implementations are thunks: they run once, on first use, so `require()` inside
one triggers lazy loading rather than defeating it. A thunk that throws is
dropped and the next implementation down takes over.

Three kinds: `callable` (a function), `value` (a datum, such as
`lsp.capabilities`), and `state` (applied once, such as the colour scheme).

`:Dohwa features` and `:checkhealth dohwa` show which implementation currently
wins every feature, and which ones lost.

## Keys

A module may only map below a prefix it reserved:

```lua
ctx:reserve("<leader>f", "Find")
ctx:slot("n", "<leader>ff", "finder.files")
```

Global keys (`gd`, `K`, `]d`, `<Tab>`) belong to `core.keys`, which binds them
to features. A module competes by implementing the feature; it never mentions
the key, so it cannot collide on one.

Three namespaces are shared, with one letter per module and a refusal by name
on a second taker:

| Namespace | Method | Used by |
|---|---|---|
| `<leader>t` | `ctx:toggle(letter, desc, fn)` | toggles |
| `]` / `[` | `ctx:jump(letter, desc, opts)` | hunks, functions, diagnostics |
| `a` / `i` | `ctx:textobject(letter, desc, opts)` | tree-sitter objects, hunks |

Mappings a plugin installs from inside its own `setup()` are declared with
`ctx:external(...)`. They are not applied — the plugin does that — but they
take part in collision detection and show up in `:Dohwa keys`.

Validation happens on the complete model, before anything is set:

- **duplicate** — two modules on the same sequence; highest priority wins, the
  loser is not applied and is reported;
- **prefix shadow** — a sequence that is both a mapping and the prefix of
  another, so the short one only fires after `timeoutlen`;
- **namespace violation** — a claim outside the owner's reservation.

## Writing a module

Drop a file in `lua/modules/<group>/<name>.lua`. Its path is its name, and that
is the whole registration. It declares up to four hooks, and which ones run is
what makes disabling safe:

| Hook | When it runs |
|---|---|
| `native(ctx)` | always, while the module is active — declares Features with their native floor, reserves the namespace, binds keys |
| `declare(ctx)` | only when the plugins will be installed — registers the better implementations, as thunks |
| `plugins(ctx)` | pure data for the loader |
| `setup(ctx)` | inside the plugin's own `config()`, so it stays lazy |

**[docs/guides/adding-a-module.md](docs/guides/adding-a-module.md)** has the full recipe: how
to classify a plugin, three worked examples from six lines upwards, the Context
API, and the five things that trip you up.

## Switching things off

```
:Dohwa disable tools.finder      persists, and says what depended on it
:Dohwa enable  tools.finder
:Dohwa why     editor.lsp        state, dependencies, dependents
:Dohwa status | graph | features | keys | log
:checkhealth dohwa
```

Hard dependencies cascade: disabling a module marks everything that requires it
as skipped, and those fall back to their native implementations. Optional
dependencies never cascade. Modules under `modules/core/` are protected and
need `--force`.

Without touching a file:

```
DOHWA_PROFILE=minimal nvim       core plus a theme
DOHWA_LOADER=null nvim           no plugins; every native fallback
DOHWA_DISABLE=tools.finder nvim  one run with a module off
```

Running as root also forces the null loader — see `init.lua`.

## Performance

Measured with `--startuptime`, median of 9 runs, on this machine. The right-hand
column is the one that matters day to day: `BufReadPre` and `BufReadPost` are
where most of the work happens, not the empty-editor startup. Run-to-run variance
is around 3 ms, so treat these as the shape of the cost rather than exact figures.

| | empty | opening a `.lua` file |
|---|---|---|
| `nvim --clean` (floor) | 7.7 ms | 16.3 ms |
| dohwa, zero plugins | 24.5 ms | 33.5 ms |
| dohwa, all 15 modules | 32.6 ms | 55.1 ms |

The kernel is not the cost: `discover` + `graph:resolve` + `keys:commit` come to
1.4 ms together, and feature dispatch — the indirection on every keypress — is
below timer resolution, because LuaJIT compiles it away.

**[docs/performance.md](docs/performance.md)** has the per-module cost, the
deferred costs, and the six decisions that were taken because a measurement
asked for them: why `vim.loader.enable()` is absent, why Mason sits on
`VeryLazy`, why Telescope has no load trigger, and how to measure a change
without fooling yourself.

## Verifying

```bash
scripts/matrix.sh lazy       # disable each module in turn, then all of them
scripts/matrix.sh null       # same, with no plugins at all
scripts/gendoc.sh --check    # generated docs, links and undocumented modules
nvim --headless "+checkhealth dohwa" +qa
```

The disable matrix is the real test: it asserts that after switching a module
off, nothing errors, no feature is left without an implementation, and no key
was refused. It finishes by checking the documentation against the live model,
so a reference page that no longer matches is a failure like any other.
