# Módulos: editor

Los cinco módulos de `lua/modules/editor/`: lo que hace de Neovim un entorno de
desarrollo. Es el grupo más caro (entre 10 y 20 ms al abrir un archivo, de los
~54 ms totales) y el que tiene los native floors más interesantes, porque en
Neovim 0.12 casi todo lo que estos plugins hacían ya existe de forma nativa.

Ninguno de los cinco tiene `requires`. Tres tienen `optional`, que solo ordena
declaraciones y nunca deshabilita nada.

## lsp

[`lua/modules/editor/lsp.lua`](../../lua/modules/editor/lsp.lua) · 390 líneas ·
`optional = { editor.complete, tools.finder }`

Servidores de lenguaje. El módulo más grande de la configuración, y la mitad de
él es la tabla `M.servers`: once servidores con su `cmd`, sus `filetypes`, sus
`root_markers` y sus `settings`.

**Native floor, y aquí no es un gesto simbólico.** En 0.12 `vim.lsp.config()` y
`vim.lsp.enable()` son nativos, así que el camino sin plugins arranca **los
mismos servidores con los mismos ajustes**, leyendo la misma tabla. Lo que
añaden los plugins es el instalador de Mason y la detección de raíz de
lspconfig. `add_mason_to_path()` pone el `bin` de Mason en el `PATH`, así que el
camino nativo sigue encontrando los servidores que Mason instaló antes aunque el
plugin esté apagado.

**Servidores:** intelephense (PHP), ts_ls, vue_ls, tailwindcss, html, cssls,
emmet_language_server, clangd, lua_ls, bashls, pyright.

**Features.**

| Feature | Kind | Rol |
|---|---|---|
| `lsp.capabilities` | value | lo **declara** aquí el consumidor, con nativo `vim.lsp.protocol.make_client_capabilities()`; `editor.complete` lo gana a 50 con `cmp_nvim_lsp`. Esta es *la* línea que antes hacía que el LSP dependiera del motor de completion |
| `lsp.servers` | state | registra y habilita los servidores. El nativo lo hace en el boot; con plugins se hace `override` para que ocurra en `setup()`, cuando lspconfig carga en `BufReadPre` |
| `code.action`, `code.rename`, `symbols.document` | — | no los declara: son slots de `core.keys` y aquí solo se les dan keys bajo `<leader>c` |

**Keys.** Reserva `<leader>c` ("Code"): `<leader>ca` acciones (n, v), `<leader>cr`
renombrar, `<leader>cs` símbolos. Toma la letra `h` de toggles para los inlay
hints.

**Plugins.**

| Plugin | Trigger | Nota |
|---|---|---|
| nvim-lspconfig | `BufReadPre`, `BufNewFile`, `dohwa_main` | **sin dependencias, a propósito**: 0.12 lee sus `lsp/*.lua` del runtimepath y nunca requiere su módulo Lua, así que es un directorio de 418 defaults, no código |
| mason.nvim | `VeryLazy` + `cmd` | es un instalador; su única contribución en runtime es una entrada de `PATH` |
| mason-lspconfig.nvim | `VeryLazy` | `automatic_enable = false`: este módulo habilita los servidores él mismo, con su propia tabla |

**Tres cosas medidas que explican la forma del archivo:**

1. **Mason colgado de lspconfig costaba 8 ms en cada archivo abierto** (mason
   1,4 ms + mason-lspconfig 6,5 ms + mason-registry), para nada. De ahí el
   `VeryLazy`.
2. **`vim.lsp.enable()` no se engancha a buffers ya abiertos**, solo a eventos
   `FileType` posteriores. Por eso el registro tiene que ocurrir en `setup()`
   sobre `BufReadPre` y no puede moverse más tarde.
3. **`guard_inlay_hints()`** envuelve `vim.lsp.inlay_hint.on_inlayhint` para
   descartar las respuestas de todo cliente que no sea el "dueño" de los hints
   del buffer. Neovim guarda una lista de hints por cliente pero una sola
   `version` para todo el buffer, así que con dos servidores sirviendo hints el
   más rápido marca el estado como actual mientras las columnas del otro apuntan
   a líneas que ya se han encogido: `Invalid 'col': out of range`. La prioridad
   la decide `hint_priority`, donde `vue_ls` vale 10 porque `ts_ls` ya lleva el
   plugin de Vue.

**Coste.** 4–7 ms al abrir un archivo.
**Apagarlo.** `:Dohwa disable editor.lsp`. Pierdes Mason y la detección de raíz
de lspconfig; **los servidores siguen arrancando** por el camino nativo si sus
binarios están en el `PATH`. `tools.finder` lo tiene como `optional`, así que no
cascadea.

## complete

[`lua/modules/editor/complete.lua`](../../lua/modules/editor/complete.lua) ·
200 líneas

Completion y snippets.

**Native floor, y en 0.12 es real:** `vim.lsp.completion.enable()` con
autotrigger mueve el popup nativo desde el servidor, `completeopt` (puesto en
`core.options`) le da matching fuzzy y popup de documentación, y `vim.snippet`
expande y navega los snippets del servidor. Apagar este módulo cuesta las
fuentes extra y los iconos, **no la completion**.

**Features.**

| Feature | Kind | Rol |
|---|---|---|
| `completion.engine` | state | declara el motor; el nativo engancha `LspAttach` → `vim.lsp.completion.enable`. nvim-cmp hace `override` porque instala su propio popup desde `setup()` |
| `lsp.capabilities` | value | lo **implementa** a 50 con `cmp_nvim_lsp.default_capabilities()`. Lo declara `editor.lsp` |

**`<Tab>` se deja deliberadamente en paz**, y el comentario que lo explica
(`complete.lua:44`) merece leerse: cmp instala su propia capa sobre lo que
`<Tab>` ya tuviera y la llama como *fallback*, así que el slot de core acaba
siendo el último eslabón de la cadena — menú de cmp, luego LuaSnip, luego el
manejo nativo de pum y `vim.snippet`, y al final un tab literal. Implementar
`completion.next` aquí sustituiría ese último eslabón y el tab normal
desaparecería.

**Keys.** Ninguna propia. Siete `external` en insert (`<CR>`, `<C-Space>`,
`<C-e>`, `<C-b>`, `<C-f>`, `<C-n>`, `<C-p>`): las instala cmp, no se aplican
aquí, pero entran en la detección de colisiones y salen en `:Dohwa keys`.

**Plugins.** nvim-cmp en `InsertEnter`/`CmdlineEnter`, con cmp-nvim-lsp,
cmp-buffer, cmp-path, LuaSnip, cmp_luasnip y friendly-snippets.

El `setup()` tiene un detalle que no es cosmético: los colores del menú se
**enlazan a grupos de tree-sitter** (`@function`, `@type`, `@keyword`…) en vez de
codificar colores, y se vuelven a enlazar en `ColorScheme`. Así el menú sigue al
tema que acabe aplicando `ui.theme` sin saber cuál es.

**Coste.** Junto con `editor.pairs`, 28 ms en la primera entrada a modo insert,
una vez por sesión.
**Apagarlo.** La completion sigue, nativa y desde el servidor. `lsp.capabilities`
cae a las capabilities de Neovim, que es exactamente para lo que ese feature
existe.

## format

[`lua/modules/editor/format.lua`](../../lua/modules/editor/format.lua) · 136 líneas

Formateo.

**Native floor.** `'formatprg'` se apunta por filetype al formateador que de
verdad esté instalado, así que `gq` y el feature `format.buffer` siguen
funcionando a través del mecanismo de filtro de Vim. El format-on-save es un
`BufWritePre` normal. La tabla `PROGRAMS` cubre lua, sh/bash y c/cpp; para los
filetypes de prettier el programa se resuelve **por buffer**, porque prettier
necesita el nombre del archivo para elegir el parser.

**Features.**

| Feature | Kind | Rol |
|---|---|---|
| `format.buffer` | callable | lo declara `core.keys`; aquí se **implementa** a 50 con `conform.format({ async = true, lsp_format = "fallback" })` |
| `format.on_save` | state | declarado aquí con nativo `BufWritePre`; conform trae el suyo, así que `override` |

**`vim.g.dohwa_format_on_save` se comparte a propósito.** Es estado genuinamente
global, y lo leen tanto el camino nativo como conform, así que `<leader>tf`
significa lo mismo por los dos caminos. Útil cuando una CLI está editando el
mismo archivo desde otro panel y no quieres que Neovim reformatee encima.

**Keys.** Solo la letra `f` del namespace de toggles.
**Plugins.** conform.nvim en `BufWritePre` + `:ConformInfo`, con
`stop_after_first` donde hay varias opciones (prettierd antes que prettier, pint
antes que php_cs_fixer).
**Apagarlo.** `<leader>==` sigue formateando por `'formatprg'` o por el LSP, y el
format-on-save sigue existiendo por el autocommand nativo con la misma bandera.

## pairs

[`lua/modules/editor/pairs.lua`](../../lua/modules/editor/pairs.lua) · 142 líneas
· `optional = { editor.complete, editor.syntax }`

Cierre automático de paréntesis y comillas. Es el módulo que mejor ilustra la
regla 2 en un caso raro: **las keys implicadas son caracteres sueltos en modo
insert**, así que el módulo reserva exactamente esos caracteres en exactamente
ese modo. A partir de ahí la regla de namespace se aplica como en cualquier otro
sitio: nada más puede mapear `(` en insert sin ser rechazado por su nombre.

**Native floor.** Mappings `<expr>` planos: `(` inserta el par, `)` salta por
encima si ya hay uno delante, las comillas no se emparejan dentro de una palabra
(el apóstrofo de *don't* no es una apertura) y `<BS>` borra las dos mitades de un
par vacío. Sin conciencia del contexto sintáctico y sin fast-wrap, pero los
paréntesis se cierran.

**Features.** Ninguno. Esto es puramente keys.

**El patrón `revoke_keys`.** nvim-autopairs instala sus propios mappings para
exactamente esas teclas, así que los nativos tienen que irse. En `declare` el
módulo llama a `ctx:revoke_keys()` — suelta todo lo que había declarado — y
vuelve a declararlo como `external`: así siguen siendo visibles en `:Dohwa keys`
y en la detección de colisiones sin aplicarse dos veces. Es la única forma
limpia de que un módulo se retracte de sus propias claims, y existe porque el
broker commitea una sola vez, después de que todos hayan hablado.

**Plugins.** nvim-autopairs en `InsertEnter`. `map_cr = false`: `<CR>` se queda
con el motor de completion — dejar que los dos lo mapeen es justo el solape que
esta configuración existe para evitar. `check_ts = true` usa tree-sitter para no
emparejar dentro de strings.

El `setup()` conecta autopairs con cmp (`confirm_done` → añadir los paréntesis
tras completar una función) **solo si `ctx:has("editor.complete")`**. Es el uso
legítimo de `ctx:has`: decidir si *ofrecer* algo, no obtener algo de otro módulo.

**Apagarlo.** Los pares siguen cerrándose, con los mappings nativos. Pierdes el
contexto sintáctico, el fast-wrap (`<M-e>`) y los paréntesis tras completar.

## syntax

[`lua/modules/editor/syntax.lua`](../../lua/modules/editor/syntax.lua) · 169 líneas

Resaltado, indentación y text objects estructurales.

**Native floor.** Neovim 0.12 trae `vim.treesitter.start()` y parsers para c,
lua, markdown, markdown_inline, query, vim y vimdoc. El nativo es un autocommand
`FileType` que intenta `vim.treesitter.start` y, si no hay parser, cae a
`vim.bo.syntax = "ON"`. Los archivos con parser incluido tienen tree-sitter de
verdad sin ningún plugin; el resto usa el motor regex.

**Features.** `syntax.engine` (state): declarado aquí con ese nativo, y
`override` en `declare` porque nvim-treesitter instala su propio manejo de
`FileType` desde `setup()`. Un no-op a prioridad más alta es cómo un módulo dice
"me hago cargo de esto".

**Keys.** Reserva `<leader>s` ("Swap"). Todo lo demás son **external**: los diez
text objects (`af`/`if`, `ac`/`ic`, `aa`/`ia`, `ai`/`ii`, `al`/`il`), los seis
saltos (`]f`/`[f`, `]C`/`[C`, `]a`/`[a`), la selección incremental
(`<C-space>`, `<BS>` en visual) y los dos swaps de parámetro. Los pide por los
namespaces compartidos: `ctx:textobject(letra, desc, { external = true })` y
`ctx:jump(...)`, así que compiten por las letras igual que todos.

`]c` se deja libre a propósito: es la motion de diff incorporada, y `tools.git`
la respeta para su navegación de hunks.

**Plugins.** nvim-treesitter (rama master) + nvim-treesitter-textobjects en
`BufReadPost`/`BufNewFile`, con 23 parsers en `ensure_installed` y
`auto_install = true`.

**El `setup()` re-registra dos directivas de query** (`set-lang-from-info-string!`
y `downcase!`) que Neovim 0.12 eliminó y que la rama master de nvim-treesitter
todavía emite. Sin eso, las inyecciones de markdown dejan de funcionar — y
siendo esta la configuración donde se lee la documentación en markdown, se nota.

**Coste.** 6–7 ms al abrir un archivo: es el módulo más caro de la
configuración.
**Apagarlo.** Resaltado tree-sitter solo para los siete lenguajes incluidos, y
regex para el resto. Pierdes los text objects estructurales, los saltos por
función y clase, y la selección incremental. `editor.pairs` lo tiene como
`optional`, así que no cascadea: solo deja de usar `check_ts`.

## Para seguir

- [../guides/adding-a-language.md](../guides/adding-a-language.md) — servidor,
  formateador y parser para un lenguaje nuevo.
- [../performance.md](../performance.md) — de dónde salen estos milisegundos.
- [tools.md](tools.md) — el finder, que compite por los features `goto.*` de este
  grupo.
