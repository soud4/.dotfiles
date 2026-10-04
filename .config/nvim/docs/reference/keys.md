<!-- Generado por scripts/gendoc.sh · no editar a mano -->

# Referencia: keys

118 mappings aplicados en 23 namespaces, tal como los dejó `KeyBroker:commit()`.

Un mapping marcado `(plugin)` es una `external` claim: lo instala el plugin,
no el broker, pero entra igual en la detección de colisiones.

Las reglas que gobiernan esta tabla están en
[../architecture.md](../architecture.md) y los procedimientos en
[../guides/changing-keys.md](../guides/changing-keys.md).

## Namespaces reservados

| Prefijo | Para | Dueño | Modos |
|---|---|---|---|
| `"` | Auto pair (plugin) | `editor.pairs` | i |
| `'` | Auto pair (plugin) | `editor.pairs` | i |
| `(` | Auto pair (plugin) | `editor.pairs` | i |
| `)` | Auto pair (plugin) | `editor.pairs` | i |
| `<leader>=` | Format | `core.keys` | todos |
| `<leader>?` | Key hints | `ui.hints` | todos |
| `<leader>F` | Native find | `core.keys` | todos |
| `<leader>c` | Code | `editor.lsp` | todos |
| `<leader>d` | Diagnostics | `core.keys` | todos |
| `<leader>f` | Find | `tools.finder` | todos |
| `<leader>g` | Git | `tools.git` | todos |
| `<leader>h` | Help & docs | `tools.docs` | todos |
| `<leader>s` | Swap (tree-sitter) | `editor.syntax` | todos |
| `<leader>t` | Toggles | `core.toggles` | todos |
| `[` | Previous | `core.keys` | n, x, o |
| `[` | Auto pair (plugin) | `editor.pairs` | i |
| `]` | Auto pair (plugin) | `editor.pairs` | i |
| `]` | Next | `core.keys` | n, x, o |
| ``` | Auto pair (plugin) | `editor.pairs` | i |
| `a` | A text object | `core.keys` | o, x |
| `i` | Inner text object | `core.keys` | o, x |
| `{` | Auto pair (plugin) | `editor.pairs` | i |
| `}` | Auto pair (plugin) | `editor.pairs` | i |

## Mappings por módulo

### core.keys

| Modo | Key | Hace |
|---|---|---|
| `n` | `<C-d>` | Half page down, centred |
| `n` | `<C-h>` | Window left |
| `n` | `<C-j>` | Window down |
| `n` | `<C-k>` | Window up |
| `n` | `<C-l>` | Window right |
| `i` | `<C-s>` | Signature help |
| `n` | `<C-u>` | Half page up, centred |
| `n` | `<Esc>` | Clear search highlight |
| `i` | `<S-Tab>` | Previous completion item / jump back in snippet |
| `s` | `<S-Tab>` | Previous completion item / jump back in snippet |
| `i` | `<Tab>` | Next completion item / jump forward in snippet |
| `s` | `<Tab>` | Next completion item / jump forward in snippet |
| `n` | `<leader>/` | Search inside this file |
| `n` | `<leader>==` | Format buffer |
| `v` | `<leader>==` | Format buffer |
| `n` | `<leader>Fb` | Switch buffer |
| `n` | `<leader>Ff` | Find file (:find) |
| `n` | `<leader>Fg` | Grep project (:grep) |
| `n` | `<leader>dd` | Show diagnostic under the cursor |
| `n` | `<leader>dl` | List diagnostics |
| `v` | `J` | Move selection down |
| `n` | `K` | Hover documentation |
| `v` | `K` | Move selection up |
| `n` | `N` | Previous match, centred |
| `n` | `[d` | Previous diagnostic |
| `n` | `]d` | Next diagnostic |
| `n` | `gD` | Go to declaration |
| `n` | `gO` | Document symbols |
| `n` | `gd` | Go to definition |
| `n` | `gi` | Go to implementation |
| `n` | `gr` | Find references |
| `n` | `gt` | Go to type definition |
| `n` | `n` | Next match, centred |

### core.toggles

| Modo | Key | Hace |
|---|---|---|
| `n` | `<leader>td` | Toggle: diagnostics |
| `n` | `<leader>tn` | Toggle: relative numbers |
| `n` | `<leader>ts` | Toggle: spell check |
| `n` | `<leader>tw` | Toggle: line wrap |

### editor.complete

| Modo | Key | Hace |
|---|---|---|
| `i` | `<C-Space>` | Trigger completion (plugin) |
| `i` | `<C-b>` | Scroll docs up (plugin) |
| `i` | `<C-e>` | Dismiss completion (plugin) |
| `i` | `<C-f>` | Scroll docs down (plugin) |
| `i` | `<C-n>` | Next item (plugin) |
| `i` | `<C-p>` | Previous item (plugin) |
| `i` | `<CR>` | Confirm completion (plugin) |

### editor.format

| Modo | Key | Hace |
|---|---|---|
| `n` | `<leader>tf` | Toggle: format on save |

### editor.lsp

| Modo | Key | Hace |
|---|---|---|
| `n` | `<leader>ca` | Code actions |
| `v` | `<leader>ca` | Code actions |
| `n` | `<leader>cr` | Rename symbol |
| `n` | `<leader>cs` | Document symbols |
| `n` | `<leader>th` | Toggle: LSP inlay hints |

### editor.pairs

| Modo | Key | Hace |
|---|---|---|
| `i` | `"` | Insert a pair (plugin) |
| `i` | `'` | Insert a pair (plugin) |
| `i` | `(` | Insert a pair (plugin) |
| `i` | `)` | Close or step over (plugin) |
| `i` | `<BS>` | Delete both halves of a pair (plugin) |
| `i` | `<M-e>` | Fast wrap (plugin) |
| `i` | `[` | Insert a pair (plugin) |
| `i` | `]` | Close or step over (plugin) |
| `i` | ``` | Insert a pair (plugin) |
| `i` | `{` | Insert a pair (plugin) |
| `i` | `}` | Close or step over (plugin) |

### editor.syntax

| Modo | Key | Hace |
|---|---|---|
| `x` | `<BS>` | Shrink syntactic selection (plugin) |
| `n` | `<C-space>` | Expand syntactic selection (plugin) |
| `x` | `<C-space>` | Expand syntactic selection (plugin) |
| `n` | `<leader>sA` | Swap with previous parameter (plugin) |
| `n` | `<leader>sa` | Swap with next parameter (plugin) |
| `n` | `[C` | Previous class (plugin) |
| `n` | `[a` | Previous parameter (plugin) |
| `n` | `[f` | Previous function (plugin) |
| `n` | `]C` | Next class (plugin) |
| `n` | `]a` | Next parameter (plugin) |
| `n` | `]f` | Next function (plugin) |
| `o` | `aa` | a parameter (plugin) |
| `x` | `aa` | a parameter (plugin) |
| `o` | `ac` | a class (plugin) |
| `x` | `ac` | a class (plugin) |
| `o` | `af` | a function (plugin) |
| `x` | `af` | a function (plugin) |
| `o` | `ai` | a conditional (plugin) |
| `x` | `ai` | a conditional (plugin) |
| `o` | `al` | a loop (plugin) |
| `x` | `al` | a loop (plugin) |
| `o` | `ia` | inner parameter (plugin) |
| `x` | `ia` | inner parameter (plugin) |
| `o` | `ic` | inner class (plugin) |
| `x` | `ic` | inner class (plugin) |
| `o` | `if` | inner function (plugin) |
| `x` | `if` | inner function (plugin) |
| `o` | `ii` | inner conditional (plugin) |
| `x` | `ii` | inner conditional (plugin) |
| `o` | `il` | inner loop (plugin) |
| `x` | `il` | inner loop (plugin) |

### tools.docs

| Modo | Key | Hace |
|---|---|---|
| `n` | `<leader>hg` | Search the documentation |
| `n` | `<leader>hh` | Browse the documentation |
| `n` | `<leader>hi` | Open the documentation index |
| `n` | `<leader>hm` | Documentation for the file being edited |
| `n` | `<leader>tm` | Toggle: markdown rendering |

### tools.finder

| Modo | Key | Hace |
|---|---|---|
| `n` | `<leader>fb` | List open buffers |
| `n` | `<leader>fc` | Find files in the Neovim config |
| `n` | `<leader>fd` | List diagnostics |
| `n` | `<leader>ff` | Find files in the project |
| `n` | `<leader>fg` | Search text in the project |
| `n` | `<leader>fh` | Search the Neovim manual |
| `n` | `<leader>fr` | Recently opened files |
| `n` | `<leader>fs` | Document symbols |
| `n` | `<leader>fw` | Search the word under the cursor |

### tools.git

| Modo | Key | Hace |
|---|---|---|
| `n` | `<leader>gR` | Reset file |
| `n` | `<leader>gb` | Blame the current line |
| `n` | `<leader>gd` | Diff this file |
| `n` | `<leader>gp` | Preview hunk |
| `n` | `<leader>gr` | Reset hunk |
| `v` | `<leader>gr` | Reset hunk |
| `n` | `<leader>tb` | Toggle: inline git blame |
| `n` | `[h` | Previous hunk |
| `n` | `]h` | Next hunk |
| `o` | `ih` | inner hunk |
| `x` | `ih` | inner hunk |

### ui.hints

| Modo | Key | Hace |
|---|---|---|
| `n` | `<leader>??` | Show available keys |
