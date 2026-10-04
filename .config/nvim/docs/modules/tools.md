# Módulos: tools

Los tres módulos de `lua/modules/tools/`: buscar, git y la documentación. Es el
grupo donde la regla 3 se ve mejor, porque `tools.finder` y `tools.docs`
colaboran sin conocerse.

## finder

[`lua/modules/tools/finder.lua`](../../lua/modules/tools/finder.lua) · 267 líneas
· `optional = { editor.lsp }`

Búsqueda fuzzy. Es el módulo que **gana más features de otros**: nueve, de los
cuales seis son slots globales de `core.keys`.

**Native floor.** `rg --files` (o `find`) metido en `vim.ui.select`, `:grep` al
quickfix, y las listas de buffers y de oldfiles incorporadas. Sin matching fuzzy
y sin preview, pero cada punto de entrada sigue funcionando y acaba en el mismo
sitio. `core.options` prepara el terreno con `path += **` y `grepprg = rg`.

**Features que declara** (siete, todos con nativo):

```
finder.files  finder.grep  finder.word  finder.buffers
finder.recent  finder.help  finder.config
```

**Features que implementa a 50**, sin declarar ninguno:

| Feature | Lo declara | Con qué |
|---|---|---|
| `goto.definition`, `goto.references`, `goto.implementation`, `goto.type_definition` | `core.keys` | pickers de `telescope.builtin` |
| `symbols.document`, `diagnostic.list` | `core.keys` | ídem |
| `search.buffer` | `core.keys` | `current_buffer_fuzzy_find` — "buscar en este archivo" tiene un significado nativo perfectamente bueno, Telescope solo es mejor |
| `docs.browse`, `docs.grep` | `tools.docs` | `find_files` / `live_grep` con `cwd = ctx:value("docs.root")` |

Eso significa que **`gd` pasa por Telescope mientras este módulo está encendido
y cae directo a `vim.lsp.buf.definition` cuando no**. No hay ningún
`pcall(require, "telescope")` en ninguna parte.

Los dos últimos son el caso interesante: implementa features que declara
`tools.docs` y lee la ruta de un `value` feature. Ninguno de los dos módulos
nombra al otro, y apagar cualquiera de los dos es seguro — si falta
`tools.docs`, `ctx:value("docs.root")` devuelve `nil` y la implementación avisa
en vez de explotar.

**Keys.** Reserva `<leader>f` ("Find"): `ff` archivos, `fg` grep, `fw` palabra
bajo el cursor, `fb` buffers, `fr` recientes, `fh` manual de Neovim, `fc`
archivos de la configuración, `fd` diagnósticos, `fs` símbolos. Las dos últimas
son slots a features de `core.keys`, así que funcionan igual con el módulo
apagado — solo cambian de interfaz.

**Plugins.** telescope.nvim con plenary, telescope-fzf-native (compilado solo si
hay `make`) y nvim-web-devicons.

**Sin `event` y sin `keys`, deliberadamente.** El broker es dueño de todos los
mappings y lazy.nvim engancha `require`, así que Telescope es `lazy = true` sin
ningún evento: carga la primera vez que un feature llama de verdad a su código.
Antes este spec no tenía trigger alguno y cargaba en el arranque, lo que lo
convertía en el plugin más caro de la configuración. La primera invocación
cuesta ~12 ms más que las siguientes.

**Apagarlo.** Todo sigue funcionando por el camino nativo: `vim.ui.select` en
vez de Telescope, `:grep` en vez de `live_grep`, y `gd` directo al LSP. Es el
módulo que mejor demuestra el diseño, porque es el que más se nota y el que
menos rompe.

## git

[`lua/modules/tools/git.lua`](../../lua/modules/tools/git.lua) · 174 líneas

Señales pasivas de git: líneas cambiadas en la columna de signos, navegación de
hunks y diffs a demanda. El trabajo de git de verdad sigue haciéndose en la
terminal.

**Es el único módulo sin native floor completo**, y lo dice en su primera línea:
Neovim no tiene seguimiento de hunks. Lo que se puede hacer nativo se hace —
blame y diff llamando a la CLI de git con `vim.system` — y el resto se declara
`optional = true`, así que con el módulo apagado esos features resuelven a nada
en vez de dar error. `:checkhealth dohwa` los lista como implementados-no-
declarados cuando toca.

**Features.**

| Feature | Nativo | Con gitsigns |
|---|---|---|
| `git.blame_line` | `git blame -L n,n` por `vim.notify` | `blame_line({ full = true })` |
| `git.diff_file` | `git diff --` en un popup con filetype `diff` | `diffthis` |
| `git.preview_hunk`, `reset_hunk`, `reset_buffer`, `select_hunk`, `hunk_next`, `hunk_prev` | ninguno (`optional`) | gitsigns |
| `git.diffstat` | — | lo **declara `ui.statusline`**, que es quien lo consume; aquí se implementa leyendo `vim.b.gitsigns_status_dict` |

`git.diffstat` es el patrón inverso al de `docs.root`: lo declara el consumidor
y lo implementa el proveedor. Por eso la rama y las cifras +/~/− simplemente
desaparecen de la statusline con este módulo apagado, en vez de dar error.

**Keys.** Reserva `<leader>g` ("Git"): `gp` preview, `gb` blame, `gd` diff, `gr`
reset hunk (n, v), `gR` reset archivo. Pide la letra `h` en los dos namespaces
compartidos de movimiento: `]h`/`[h` para saltar hunks y `ih` como text object.
Y la letra `b` de toggles para el blame en línea.

**La navegación de hunks respeta el modo diff:** si `vim.wo.diff` está activo,
`]h` hace `]c`, que es la motion correcta ahí. Por eso `editor.syntax` deja `]c`
libre.

**Plugins.** gitsigns.nvim en `BufReadPre`/`BufNewFile`. Los signos son finos
para caber en la columna que `signcolumn=yes` ya reserva, así que no desplazan
el texto nunca. El blame permanente va apagado por defecto: es ruido visual, y
`<leader>tb` lo enciende.

**Coste.** ~4 ms al abrir un archivo.
**Apagarlo.** Blame y diff siguen, por la CLI. Pierdes los signos, los hunks, la
navegación y las cifras de la statusline.

## docs

[`lua/modules/tools/docs.lua`](../../lua/modules/tools/docs.lua) · 404 líneas ·
`optional = { editor.syntax }`

El lector de esta documentación. Es el módulo más reciente y el que se escribió
para resolver el problema de que esta configuración era demasiado grande para
caber en un README.

**Native floor.** Las páginas de `docs/*.md` listadas por `vim.ui.select`,
abiertas en una pestaña propia con conceal activado y con `gO` para el índice de
la página — que Neovim trae de serie para markdown desde 0.11. Seguir enlaces
entre páginas es un parser de `[texto](destino)` de veinte líneas. **Ningún
plugin participa en leer la documentación**; render-markdown solo hace más
bonitos los mismos buffers.

**Features.**

| Feature | Kind | Rol |
|---|---|---|
| `docs.root` | value | dónde vive la documentación. Lo publica para que un finder pueda ofrecer un picker con preview sin que este módulo nombre nunca a Telescope |
| `docs.browse` | callable | selector de páginas; `tools.finder` lo gana a 50 |
| `docs.grep` | callable | buscar en la documentación; `tools.finder` lo gana a 50 |
| `docs.index` | callable | abrir `docs/README.md` |
| `docs.module` | callable | la página del archivo que estás editando |
| `docs.render` | state | nativo `conceallevel=2` + `concealcursor=nc`; render-markdown hace `override` porque gestiona esas opciones por ventana él mismo |

**Keys.** Reserva `<leader>h` ("Help & docs"):

| Key | Hace |
|---|---|
| `<leader>hh` | selector de páginas |
| `<leader>hi` | índice |
| `<leader>hg` | buscar en la documentación |
| `<leader>hm` | la página del archivo actual |
| `<leader>tm` | letra `m` de toggles: renderizado |

Más el comando `:Docs <tab>`, con completado sobre los nombres de página.

**Las keys locales del viewer** no pasan por el broker, porque son locales de
buffer y se instalan desde un autocommand `FileType` restringido a los archivos
bajo `docs/` (y al README raíz): `<CR>`/`gf` sigue el enlace, `<BS>` vuelve por
el jumplist, `q` cierra. `q` comprueba `vim.fn.reg_recording()` primero: tragarse
la única tecla que detiene una grabación de macro sería una trampa.

La resolución de `<leader>hm` está en `page_for_current_file()`: un módulo va a
la página de su grupo con su nombre como anchor, un archivo del kernel a
`kernel.md`, y un profile a `profiles.md`. El contrato de los anchors está en
[../plan.md](../plan.md#contrato-de-los-anchors).

**Plugins.** render-markdown.nvim con `ft = { "markdown" }` y nvim-web-devicons.
`anti_conceal` está activado para la línea del cursor, así que la página sigue
siendo editable en vez de convertirse en una vista de solo lectura — útil, porque
estos archivos se corrigen leyéndolos.

**Coste.** ~1 ms en el arranque. render-markdown añade ~24 ms la primera vez que
abres un `.md`, y nada en cualquier otro buffer.
**Apagarlo.** La documentación se sigue leyendo con `vim.ui.select` y conceal
nativo; pierdes el renderizado. Si en cambio apagas `tools.finder`, pierdes el
preview del selector pero no el selector.

## Para seguir

- [../architecture.md](../architecture.md#3-los-módulos-no-se-referencian-entre-sí)
  — el patrón `docs.root` explicado desde el diseño.
- [ui.md](ui.md) — la statusline, que declara `git.diffstat`.
- [../guides/adding-a-module.md](../guides/adding-a-module.md) — `tools.docs` es
  un ejemplo completo y reciente de los cuatro hooks.
