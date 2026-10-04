<!-- Generado por scripts/gendoc.sh · no editar a mano -->

# Referencia: dependencias

El orden de carga que resolvió `Graph:resolve()`. `requires` es dura —si
falta, el dependiente se salta, en cascada— y `optional` solo ordena las
declaraciones. Ver [../kernel.md](../kernel.md#graph).

## Orden de carga

| # | Módulo | requires | optional | Lo necesitan |
|---|---|---|---|---|
| 1 | `core.autocmds` | — | — | — |
| 2 | `core.keys` | — | — | — |
| 3 | `core.options` | — | — | — |
| 4 | `core.toggles` | — | — | — |
| 5 | `editor.complete` | — | — | — |
| 6 | `editor.format` | — | — | — |
| 7 | `editor.lsp` | — | `editor.complete` `tools.finder` | — |
| 8 | `editor.pairs` | — | `editor.complete` `editor.syntax` | — |
| 9 | `editor.syntax` | — | — | — |
| 10 | `tools.docs` | — | `editor.syntax` | — |
| 11 | `tools.finder` | — | `editor.lsp` | — |
| 12 | `tools.git` | — | — | — |
| 13 | `ui.hints` | — | — | — |
| 14 | `ui.statusline` | — | — | — |
| 15 | `ui.theme` | — | — | — |
