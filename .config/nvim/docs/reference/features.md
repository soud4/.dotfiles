<!-- Generado por scripts/gendoc.sh · no editar a mano -->

# Referencia: features

48 features. La columna *gana* es quién manda ahora mismo y con qué prioridad; *pierden* son las implementaciones que quedaron debajo.

`0` es siempre el native floor. Un feature `optional` puede no resolver a
nada: significa que Neovim no tiene equivalente nativo. Ver
[../guides/adding-a-feature.md](../guides/adding-a-feature.md).

| Feature | Kind | Declara | Gana | Pierden |
|---|---|---|---|---|
| `code.action` | callable | `core.keys` | `core.keys:0` | — |
| `code.rename` | callable | `core.keys` | `core.keys:0` | — |
| `completion.engine` | state | `editor.complete` | `editor.complete:50` | `editor.complete:0` |
| `completion.next` | callable | `core.keys` | `core.keys:0` | — |
| `completion.prev` | callable | `core.keys` | `core.keys:0` | — |
| `diagnostic.current` | callable | `core.keys` | `core.keys:0` | — |
| `diagnostic.list` | callable | `core.keys` | `tools.finder:50` | `core.keys:0` |
| `diagnostic.next` | callable | `core.keys` | `core.keys:0` | — |
| `diagnostic.prev` | callable | `core.keys` | `core.keys:0` | — |
| `doc.hover` | callable | `core.keys` | `core.keys:0` | — |
| `doc.signature` | callable | `core.keys` | `core.keys:0` | — |
| `docs.browse` | callable | `tools.docs` | `tools.finder:50` | `tools.docs:0` |
| `docs.grep` | callable | `tools.docs` | `tools.finder:50` | `tools.docs:0` |
| `docs.index` | callable | `tools.docs` | `tools.docs:0` | — |
| `docs.module` | callable | `tools.docs` | `tools.docs:0` | — |
| `docs.render` | state | `tools.docs` | `tools.docs:50` | `tools.docs:0` |
| `docs.root` | value | `tools.docs` | `tools.docs:0` | — |
| `finder.buffers` | callable | `tools.finder` | `tools.finder:50` | `tools.finder:0` |
| `finder.config` | callable | `tools.finder` | `tools.finder:50` | `tools.finder:0` |
| `finder.files` | callable | `tools.finder` | `tools.finder:50` | `tools.finder:0` |
| `finder.grep` | callable | `tools.finder` | `tools.finder:50` | `tools.finder:0` |
| `finder.help` | callable | `tools.finder` | `tools.finder:50` | `tools.finder:0` |
| `finder.recent` | callable | `tools.finder` | `tools.finder:50` | `tools.finder:0` |
| `finder.word` | callable | `tools.finder` | `tools.finder:50` | `tools.finder:0` |
| `format.buffer` | callable | `core.keys` | `editor.format:50` | `core.keys:0` |
| `format.on_save` | state | `editor.format` | `editor.format:50` | `editor.format:0` |
| `git.blame_line` | callable | `tools.git` | `tools.git:50` | `tools.git:0` |
| `git.diff_file` | callable | `tools.git` | `tools.git:50` | `tools.git:0` |
| `git.diffstat` | value | `ui.statusline` | `tools.git:50` | — |
| `git.hunk_next` | callable | `tools.git` | `tools.git:50` | — |
| `git.hunk_prev` | callable | `tools.git` | `tools.git:50` | — |
| `git.preview_hunk` | callable | `tools.git` | `tools.git:50` | — |
| `git.reset_buffer` | callable | `tools.git` | `tools.git:50` | — |
| `git.reset_hunk` | callable | `tools.git` | `tools.git:50` | — |
| `git.select_hunk` | callable | `tools.git` | `tools.git:50` | — |
| `goto.declaration` | callable | `core.keys` | `core.keys:0` | — |
| `goto.definition` | callable | `core.keys` | `tools.finder:50` | `core.keys:0` |
| `goto.implementation` | callable | `core.keys` | `tools.finder:50` | `core.keys:0` |
| `goto.references` | callable | `core.keys` | `tools.finder:50` | `core.keys:0` |
| `goto.type_definition` | callable | `core.keys` | `tools.finder:50` | `core.keys:0` |
| `hints.show` | callable | `ui.hints` | `ui.hints:50` | `ui.hints:0` |
| `lsp.capabilities` | value | `editor.lsp` | `editor.complete:50` | `editor.lsp:0` |
| `lsp.servers` | state | `editor.lsp` | `editor.lsp:50` | `editor.lsp:0` |
| `search.buffer` | callable | `core.keys` | `tools.finder:50` | `core.keys:0` |
| `symbols.document` | callable | `core.keys` | `tools.finder:50` | `core.keys:0` |
| `syntax.engine` | state | `editor.syntax` | `editor.syntax:50` | `editor.syntax:0` |
| `ui.colorscheme` | state | `ui.theme` | `ui.theme:50` | `ui.theme:0` |
| `ui.statusline` | state | `ui.statusline` | `ui.statusline:50` | `ui.statusline:0` |

## Sin native floor (`optional`)

Estos no tienen implementación nativa porque Neovim no hace nada
equivalente. Con su módulo apagado resuelven a nada, en silencio.

- `git.diffstat` — Added/changed/removed line counts
- `git.hunk_next` — Next hunk
- `git.hunk_prev` — Previous hunk
- `git.preview_hunk` — Preview hunk
- `git.reset_buffer` — Reset file
- `git.reset_hunk` — Reset hunk
- `git.select_hunk` — Hunk as a text object
