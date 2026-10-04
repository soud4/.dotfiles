# Módulos: core

Los cuatro módulos de `lua/modules/core/`. Son **protected**: llevan el suelo
del editor, así que `:Dohwa disable` los rechaza sin `--force`. Ninguno tiene
plugins, ninguno tiene dependencias, y son los únicos que pueden mapear fuera de
una reserva — ese privilegio lo concede el paso 3 del boot y es lo que les
permite ser dueños de las keys globales.

Son también el único grupo que el profile `minimal` enciende entero.

## options

[`lua/modules/core/options.lua`](../../lua/modules/core/options.lua) · 93 líneas

Las opciones del editor. Neovim puro: no sabe de ningún plugin y nadie depende
de él para arrancar.

**Native floor.** Es *todo* native floor; no hay nada que apagar. Lo que importa
aquí es que varias opciones existen precisamente para sostener el native floor
de otros módulos:

| Opción | Sostiene |
|---|---|
| `completeopt = menu,menuone,noselect,fuzzy,popup` | la completion nativa de `editor.complete`: es lo que usan `<C-n>` y `<C-x><C-o>` con el módulo apagado |
| `path += **`, `wildmenu`, `wildoptions=pum` | el `:find **/nombre` que es el suelo de `tools.finder` |
| `grepprg = rg --vimgrep --smart-case` | el `:grep` al quickfix que sustituye a `live_grep` |
| `foldexpr = v:lua.vim.treesitter.foldexpr()` | folding sin plugin; devuelve 0 para filetypes sin parser, así que es seguro con `editor.syntax` apagado |
| `winborder = ctx.ui.border` | un solo borde para todos los floats de la configuración |
| `autoread` | trabaja junto al `:checktime` de `core.autocmds` |

**La presentación de los diagnósticos vive aquí, no en `editor.lsp`.** Es
deliberado: el aspecto de un error no debe cambiar porque apagues un plugin.
`virtual_lines = { current_line = true }`, `virtual_text = false` y los iconos
salen de `core/ui.lua`.

**Features.** Ninguno. No declara ni implementa nada.
**Keys.** Ninguna.
**Apagarlo.** `--force`, y te quedas con los defaults de Neovim: sin
`clipboard=unnamedplus`, sin `undofile`, sin `ignorecase`, con `timeoutlen=1000`.
Nada se rompe, pero el editor deja de ser este editor.

## keys

[`lua/modules/core/keys.lua`](../../lua/modules/core/keys.lua) · 297 líneas

**El único módulo dueño de keys globales**, y el que declara 18 de los 48
features del sistema. Es el archivo que hay que leer para entender la regla 2 en
la práctica.

**Native floor.** Cada feature que declara trae su implementación nativa, y hay
tres patrones distintos según lo que Neovim pueda hacer solo:

| Patrón | Qué hace | Features |
|---|---|---|
| `lsp_or_builtin` | el LSP si hay servidor, el comando de Vim si no (`normal!` para no recursar en el propio slot) | `goto.definition`, `goto.declaration`, `doc.hover` |
| `lsp_only` | avisa de que no hay servidor en vez de fingir | `goto.implementation`, `code.action`, `code.rename`… |
| nativo completo | no necesita LSP en absoluto | los cuatro `diagnostic.*`, `completion.next/prev`, `search.buffer` |

`goto.references` es el caso más bonito: sin servidor hace `:grep` de la palabra
bajo el cursor al quickfix, que es el equivalente nativo honesto de "buscar
referencias".

**Features que declara** (todas con nativo a prioridad 0):

```
goto.definition  goto.declaration  goto.implementation  goto.type_definition
goto.references  doc.hover  doc.signature  symbols.document
code.action  code.rename  format.buffer  search.buffer
diagnostic.current  diagnostic.next  diagnostic.prev  diagnostic.list
completion.next  completion.prev
```

De esas, seis las acaba ganando `tools.finder` y una `editor.format`. Las
demás se quedan en el nativo, hagas lo que hagas con los plugins.

**Keys.** Slots globales (key → feature, resuelto al pulsar):

| Key | Feature |
|---|---|
| `gd` `gD` `gr` `gi` `gt` | `goto.definition` · `declaration` · `references` · `implementation` · `type_definition` |
| `gO` | `symbols.document` |
| `K` | `doc.hover` |
| `<C-s>` (insert) | `doc.signature` — `<C-k>` se queda como navegación de ventanas |
| `<Tab>` `<S-Tab>` (insert, select) | `completion.next` / `prev` |
| `<leader>dd` `<leader>dl` | `diagnostic.current` / `list` |
| `<leader>/` | `search.buffer` |
| `<leader>==` | `format.buffer` |

Y mappings planos, que no pertenecen a ningún feature porque no hay nada que un
plugin pudiera querer sobrescribir en ellos: `<Esc>` limpia el resaltado,
`<C-hjkl>` navega ventanas, `J`/`K` en visual mueven la selección, `<C-d>`/`<C-u>`
y `n`/`N` centran, y `<leader>F{f,g,b}` es la navegación nativa del proyecto
(`:find`, `:grep`, `:buffer`) que queda por debajo de Telescope.

**Reserva los namespaces compartidos** para que otros módulos pidan letras:
`]`/`[` (modos n, x, o), `a`/`i` (o, x), más `<leader>d`, `<leader>=` y
`<leader>F` para sí mismo. Toma la letra `d` de saltos para los diagnósticos.

**Un detalle que parece un hack y no lo es:** borra los mappings `grn`, `gra`,
`grr`, `gri`, `grt` que Neovim 0.11 trae de serie. Esta configuración mapea `gr`
en sí mismo, así que cada uno de ellos haría esperar `timeoutlen` — un prefix
shadow introducido por el propio Neovim.

**Apagarlo.** `--force`. Te quedas sin keys globales y sin los namespaces
compartidos, así que `core.toggles`, `tools.git` y `editor.syntax` pierden sus
letras de salto y de text object. Es el módulo menos razonable de apagar.

## autocmds

[`lua/modules/core/autocmds.lua`](../../lua/modules/core/autocmds.lua) · 59 líneas

Cinco autocommands que pertenecen al editor en sí, cada uno en su propio augroup
(`ctx:augroup("yank")`, `"cursor"`, `"quickclose"`, `"reload"`,
`"reload.notify"`), así que se pueden inspeccionar y borrar por separado.

| Autocommand | Hace |
|---|---|
| `TextYankPost` | resalta brevemente lo copiado |
| `BufReadPost` | restaura la última posición del cursor |
| `FileType` | `q` cierra ventanas auxiliares: `help`, `lspinfo`, `man`, `notify`, `qf`, `checkhealth`, `dohwa` |
| `FocusGained`, `TermClose`, `TermLeave`, `BufEnter`, `CursorHold` | `:checktime` para recargar el buffer si el archivo cambió en disco |
| `FileChangedShellPost` | avisa de que lo ha recargado |

El autocommand de recarga tiene dos detalles medidos: `autoread` por sí solo no
basta, porque Neovim solo mira el disco cuando se le pide; y el `:checktime`
tiene que ir dentro de un `vim.schedule`, porque uno emitido desde dentro de un
autocommand se posterga y el buffer nunca se recarga de verdad. Importa cuando
tienes una CLI editando el mismo archivo desde otro panel de tmux.

**Features.** Ninguno.
**Keys.** Solo la `q` local de buffer en ventanas auxiliares, que va por
`vim.keymap.set` directo porque es local de buffer y no entra en el arbitraje.
**Apagarlo.** `--force`. Pierdes las cinco comodidades; nada más depende de
ellas.

## toggles

[`lua/modules/core/toggles.lua`](../../lua/modules/core/toggles.lua) · 33 líneas

El dueño del namespace compartido `<leader>t`. Treinta y tres líneas que existen
para que **ningún módulo mapee una key de toggle por su cuenta**: piden una
letra con `ctx:toggle(letra, desc, fn)` y el broker rechaza a quien llegue
segundo, nombrando a los dos.

Sus cuatro toggles propios: `w` wrap, `d` diagnósticos, `n` números relativos,
`s` corrector ortográfico.

Las letras que reparte a los demás, y quién las tiene ahora mismo:

| Letra | Toggle | Dueño |
|---|---|---|
| `b` | git blame en línea | `tools.git` |
| `f` | format on save | `editor.format` |
| `h` | inlay hints del LSP | `editor.lsp` |
| `m` | renderizado de markdown | `tools.docs` |
| `w` `d` `n` `s` | wrap, diagnósticos, números, spell | `core.toggles` |

**Apagarlo.** `--force`, y entonces **ningún** toggle de ningún módulo se aplica:
`ctx:toggle` falla con `no toggle namespace` porque nadie reservó el prefijo.
Es el ejemplo más claro de un módulo cuya ausencia se nota en otros cuatro, sin
que ninguno de ellos lo mencione. `scripts/matrix.sh` lo cubre: apagarlo sigue
dando OK porque los rechazos de letra no son errores de feature, pero
`:checkhealth dohwa` lista los cuatro rechazos.

## Para seguir

- [editor.md](editor.md) — lo que se construye encima de este suelo.
- [../architecture.md](../architecture.md) — por qué los slots evitan las
  colisiones.
- [../guides/changing-keys.md](../guides/changing-keys.md) — mover una de estas
  keys.
