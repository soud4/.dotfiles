# Glosario

El vocabulario de esta configuración. Los términos se mantienen en inglés porque
son los que aparecen en el código: traducirlos aquí y no allí sería peor que no
traducirlos en ningún sitio.

Ordenado de lo más central a lo más específico, no alfabéticamente: leído de
arriba abajo cuenta una historia.

## module

Una unidad conmutable de configuración: un archivo en
`lua/modules/<grupo>/<nombre>.lua`. Su ruta es su nombre, así que
`tools/git.lua` es `tools.git` y dejar el archivo ahí *es* todo el registro. Es
una tabla declarativa, no una clase, y declara hasta cuatro **hooks**.

Un módulo bajo `modules/core/` es un **protected module**: lleva el suelo del
editor, así que `:Dohwa disable` lo rechaza sin `--force`.

## hook

Una de las cuatro funciones que puede declarar un módulo. Cuáles corren es lo
que hace que apagar sea seguro:

| Hook | Corre |
|---|---|
| `native(ctx)` | siempre, con el módulo activo — incluso sin plugins |
| `declare(ctx)` | solo si los plugins se van a instalar |
| `plugins(ctx)` | datos puros para el loader |
| `setup(ctx)` | dentro del `config()` del plugin, así que sigue siendo lazy |

## native floor

Lo que queda cuando un módulo se apaga, o cuando no hay ningún plugin: la
implementación a prioridad 0 de cada **feature**, hecha solo con lo que Neovim
ya trae. No es un modo degradado de emergencia, es la línea base que se prueba
en cada cambio con `scripts/matrix.sh null`.

La pregunta que hay que hacerse antes de decidir que algo "no tiene nativo" está
en [guides/adding-a-module.md](guides/adding-a-module.md): `gc` para comentarios,
netrw, `vim.ui.open`, `vim.ui.select`, `vim.snippet`, `vim.lsp.*`,
`vim.treesitter.*`, `:grep` al quickfix, `'formatprg'`.

## feature

Una capacidad con nombre y varias implementaciones ordenadas por prioridad. Es
la única abstracción de la configuración para tres cosas: el native fallback, el
destino de una key global y una capacidad compartida entre módulos.

Prioridad **0** es el nativo, lo declara el dueño del concepto y no se elimina
nunca. **50** es la convención para una implementación con plugin.

Tres **kinds**:

- `callable` — una función que se invoca (`goto.definition`, `finder.files`).
- `value` — un dato (`lsp.capabilities`, `docs.root`).
- `state` — algo que se aplica una vez, al final del boot (`syntax.engine`, el
  colorscheme).

## thunk

Un provider: una función que **devuelve** la implementación en vez de ser la
implementación. Corre como máximo una vez, en el primer uso.

Es lo que permite que una implementación haga `require("telescope.builtin")` sin
forzar la carga del plugin en el arranque. Por eso pasar `vim.lsp.buf.definition`
directamente es un error: eso resuelve `vim.lsp.buf` en el momento de declarar y
se lleva el arranque por delante.

Un thunk que lanza se descarta y gana el siguiente hacia abajo. Un plugin roto
degrada, no rompe.

## declare / implement / override

- **declare** — crear el concepto y su native floor. Lo hace el dueño, una sola
  vez; declararlo dos veces es un error registrado.
- **implement** — competir por un feature, con una prioridad y un thunk.
  Implementar uno no declarado crea un **placeholder**: es legítimo y es como
  dos módulos se encuentran sin conocerse.
- **override** — decir "me hago cargo de este `state`" registrando un no-op a
  prioridad 50, porque el plugin ya lo hace desde su `setup()`.

## slot

Una key atada a un **feature** en vez de a una implementación. Se resuelve en el
momento de pulsarla, así que manda quien gane el feature entonces.

Las keys globales (`gd`, `K`, `<Tab>`) son slots de `core.keys`. Un módulo
compite implementando el feature y **nunca menciona la key**, que es por lo que
no puede colisionar en ella.

## reservation / namespace

Un prefijo del que un módulo es dueño exclusivo, pedido con `ctx:reserve()`. Un
módulo solo puede mapear por debajo de un prefijo que haya reservado; cualquier
otra cosa es una **namespace violation** y se rechaza.

Dos reservas del mismo prefijo solo chocan si sus **modos** se solapan: `[` en
insert y `[` en normal son namespaces distintos.

### namespace compartido

Tres prefijos se reparten por letras, con una letra por módulo y un rechazo
nominal al segundo que la pida:

| Namespace | Método | Lo usan |
|---|---|---|
| `<leader>t` | `ctx:toggle(letra, desc, fn)` | toggles |
| `]` / `[` | `ctx:jump(letra, desc, opts)` | hunks, funciones, diagnósticos |
| `a` / `i` | `ctx:textobject(letra, desc, opts)` | objetos de tree-sitter, hunks |

## external claim

Un mapping que el plugin instala por su cuenta desde su `setup()`, declarado con
`ctx:external()`. **No se aplica** — ya lo hace el plugin — pero entra en la
detección de colisiones y aparece en `:Dohwa keys`. Sin esto, los mappings
internos de un plugin serían invisibles para el arbitraje.

## duplicate / prefix shadow

Los dos problemas que encuentra el **KeyTrie** al validar el modelo completo:

- **duplicate** — dos módulos en la misma secuencia. Gana la prioridad más alta,
  el perdedor no se aplica y se reporta.
- **prefix shadow** — una secuencia que es a la vez mapping y prefijo de otra
  (`<leader>f` existiendo `<leader>ff`). Ambas se aplican, pero la corta solo
  dispara tras `timeoutlen`. Es un bug de **latencia**, invisible en una
  configuración normal, y sale en `:checkhealth dohwa`.

## requires / optional

Los dos tipos de arista del **Graph**:

- **`requires`** (dura) — si falta, el dependiente se deshabilita, y el efecto
  cascadea transitivamente. Estado `skipped`.
- **`optional`** (blanda) — no deshabilita nunca. Solo ordena las declaraciones,
  para que una capacidad esté registrada antes de que alguien la busque.

Un ciclo hecho solo de aristas opcionales no es un ciclo: se rompe, se anuncia
en `:Dohwa log` y el arranque continúa.

## profile

Qué módulos están encendidos: un archivo en `lua/profiles/`. `default` tiene
todo y `minimal` solo el core más un tema. `spec.default` decide qué pasa con un
módulo que no está listado, que es lo que hace que dejar un archivo nuevo
funcione sin tocar nada más.

Precedencia, de más fuerte a más débil: `DOHWA_DISABLE` → el archivo de estado
JSON que escribe `:Dohwa disable` → el profile → `spec.default`.

## loader

Cómo llegan los plugins al runtimepath, como interfaz. `LazyLoader` usa
lazy.nvim; `NullLoader` no instala nada y es el test de aceptación del native
floor. `DOHWA_LOADER` elige, y correr como root fuerza `null`.

## state (de un módulo)

En qué situación está un módulo, con su marca en `:Dohwa status`:

| Estado | Marca | Significa |
|---|---|---|
| `active` | `+` | corriendo |
| `disabled` | `-` | el profile o `:Dohwa disable` lo apagaron |
| `skipped` | `~` | le falta una dependencia dura; sus features caen al nativo |
| `error` | `!` | un hook lanzó, o el archivo no carga |
| `pending` | `?` | descubierto pero el boot aún no lo ha resuelto |

## orphan feature

Un feature sin ninguna implementación y sin `optional`. `:checkhealth dohwa` lo
marca como error, porque significa que una key o una llamada no hace nada. Es lo
que `scripts/matrix.sh` comprueba después de apagar cada módulo, y la razón de
que esa matriz sea la prueba de verdad del diseño.
