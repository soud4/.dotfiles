# Arquitectura

Esta es la página que explica el *por qué*. El código ya dice el *qué*, y lo
dice bien: si buscas la mecánica exacta de una pieza, [kernel.md](kernel.md) te
manda al archivo y a la línea.

La configuración no está organizada por plugins, sino por **unidades
conmutables**. Un módulo es un archivo en `lua/modules/<grupo>/<nombre>.lua`, y
la pregunta que gobierna todo el diseño es: *¿qué pasa cuando lo apago?* La
respuesta tiene que ser siempre "sigues teniendo un editor", y las tres reglas
existen para que esa respuesta no dependa de la disciplina de quien escribe el
módulo.

## Las tres reglas

### 1. Todo módulo tiene un native floor

Cada capacidad se declara como un **feature** con una implementación nativa a
prioridad 0. Esa implementación no usa plugins: usa lo que Neovim ya trae.
`gd` cae en `vim.lsp.buf.definition()` y, si no hay servidor, en el `gd` del
propio Vim ([`lua/modules/core/keys.lua:36`](../lua/modules/core/keys.lua)).
Buscar archivos sin Telescope es `rg --files` metido en `vim.ui.select`
([`lua/modules/tools/finder.lua:25`](../lua/modules/tools/finder.lua)).

La prioridad 0 nunca se elimina: `Feature:revoke()` quita las
implementaciones de un dueño, y el nativo pertenece a quien declaró el concepto,
que es el módulo que no se está apagando. Por eso apagar algo degrada en vez de
romper.

El test de esta regla no es una opinión, es ejecutable:

```
DOHWA_LOADER=null nvim        # cero plugins, todos los native floors
scripts/matrix.sh null
```

### 2. Ningún módulo puede colisionar con otro en una key

Dos mecanismos, y entre los dos no queda hueco:

- **Namespaces exclusivos.** Un módulo solo puede mapear por debajo de un
  prefijo que haya reservado con `ctx:reserve()`. Cualquier otra cosa se
  rechaza. Un segundo módulo que pida el mismo prefijo recibe un `reservation
  taken` con el nombre del dueño.
- **Slots.** Las keys globales (`gd`, `K`, `]d`, `<Tab>`) pertenecen a
  `core.keys`, que las ata a un *feature*, no a una implementación. Un módulo
  compite implementando el feature; **nunca menciona la key**, así que no tiene
  forma de colisionar en ella. Mover `gd` para toda la configuración es una
  línea en un solo archivo.

Tres namespaces se comparten por letras, con una letra por módulo y un rechazo
nominal al segundo que la pida: `<leader>t` para toggles, `]`/`[` para saltos y
`a`/`i` para text objects.

Nada llega a `vim.keymap.set` hasta que el modelo completo está validado. La
validación encuentra tres clases de problema, y la tercera es la interesante:

| Clase | Qué es |
|---|---|
| duplicate | dos módulos en la misma secuencia; gana la prioridad más alta, el perdedor no se aplica y se reporta |
| namespace violation | una claim fuera de la reserva del dueño |
| prefix shadow | una secuencia que es a la vez mapping y prefijo de otra, así que la corta solo dispara tras `timeoutlen` |

El *prefix shadow* es un bug de latencia que en una configuración normal es
invisible: nadie lo reporta, solo se siente como que el editor "va lento". Aquí
sale en `:checkhealth dohwa` porque el modelo de keys es un dato antes de ser
un efecto.

### 3. Los módulos no se referencian entre sí

No hay `require("telescope")` fuera del módulo que lo instala, y no hay
`require("modules.editor.lsp")` en ninguna parte. Los módulos se encuentran por
**nombre de feature**:

```lua
-- tools/docs.lua publica dónde vive la documentación
ctx:declare("docs.root", { kind = "value", native = function() return root() end })

-- tools/finder.lua ofrece un picker sobre ese directorio sin saber de quién es
ctx:implement("docs.browse", 50, function()
  return function()
    require("telescope.builtin").find_files({ cwd = ctx:value("docs.root") })
  end
end)
```

`tools.finder` implementa un feature que no declaró. El registry lo permite a
propósito: crea un *placeholder*
([`lua/dohwa/registry.lua:59`](../lua/dohwa/registry.lua)) para que ninguno de
los dos módulos tenga que conocer el ciclo de vida del otro. Gane quien gane la
carrera de arranque, apagar cualquiera de los dos sigue siendo seguro.

## El object model

```
Object                   new() · extend() · is_a()
├── Dohwa                el objeto maestro: módulos, graph, registry, broker, boot
├── Module               ciclo de vida de una unidad
│   ├── CoreModule       protegido; todo lo que está bajo modules/core/
│   └── PluginModule     aporta specs al loader
├── Loader               interfaz
│   ├── LazyLoader       lazy.nvim
│   └── NullLoader       ningún plugin
├── Feature              una capacidad con implementaciones ordenadas por prioridad
├── FeatureRegistry      todos los features del sistema
├── KeyBroker            propiedad y arbitraje de keys
│   └── KeyTrie          detección de duplicados y de prefix shadows
├── Graph                orden topológico, ciclos, dependencias inversas
├── Profile              qué está encendido, y dónde se recuerda
└── Context              el handle que recibe un módulo (`ctx`)
```

**Los módulos no son clases.** Son tablas declarativas planas. Son singletons:
instanciarlos no compraría nada y les permitiría esconder estado, que es
exactamente lo que rompe el lazy loading. Un módulo declara hasta cuatro
funciones y ninguna de ellas guarda nada entre arranques.

Hay una excepción deliberada a "todo es un módulo": `lua/core/ui.lua`. Son
tokens visuales compartidos (el borde, los iconos) y se requiere directamente
porque hacen falta *mientras* los módulos se están declarando, antes de que
exista ningún orden de carga. Antes de que existiera, `"single"` estaba repetido
en cinco archivos y los iconos de diagnóstico en tres copias.

## El boot, paso a paso

Todo arranca con tres líneas en `init.lua`: los leaders (tienen que estar antes
de que algo mapee contra ellos), el null loader forzado si corres como root, y
`require("dohwa"):boot()`.

`Dohwa:boot()` ([`lua/dohwa/init.lua:98`](../lua/dohwa/init.lua)) hace ocho
cosas, y el orden es el argumento central del diseño:

| # | Paso | Por qué va aquí |
|---|---|---|
| 0 | `discover()` | Cada `lua/modules/**/*.lua` es un módulo y su ruta es su nombre. No hay índice que actualizar: dejar el archivo *es* el registro. Un módulo que no carga se convierte en estado `error`, no en un arranque abortado. |
| 1 | Qué quiere el profile | Se construye el graph completo (incluso con los módulos apagados) antes de decidir, para poder responder "¿quién dependía de esto?" aunque esté off. |
| 2 | Resolver orden y cascada | `requires` que falta deshabilita al dependiente, transitivamente. `optional` nunca deshabilita: solo ordena. |
| 3 | Privilegios | Los módulos protegidos (`modules/core/`) son los únicos que pueden mapear fuera de una reserva. |
| 4 | **Pass A: natives** | Corre siempre para un módulo activo. Al acabar, el suelo existe entero: todos los features declarados, todos los namespaces reservados. Haya plugins o no. |
| 5 | **Pass B: declare** | Solo si los plugins se van a instalar. Registra las implementaciones mejores como *thunks*: nada se requiere todavía. |
| 6 | `keys:commit()` | El modelo de keys **completo** se valida de una vez y después se aplica. Validar por partes no detectaría un prefix shadow entre dos módulos. |
| 7 | Entregar specs al loader | El loader se encarga de que `setup(ctx)` corra cuando el plugin cargue de verdad. |
| 8 | Activar los `state` features | Colorscheme y statusline se aplican al final, cuando ya se sabe quién ganó. |

La separación entre el paso 4 y el paso 5 es lo que hace que apagar sea seguro.
Con el null loader, o cuando un módulo se salta por una dependencia que falta,
los pasos 5 y 7 no ocurren para él y todos sus features se quedan en su
implementación de prioridad 0.

## El ciclo de vida de un feature

```
declare(nombre, { kind, desc, native })      prioridad 0, la declara el dueño del concepto
   └── implement(nombre, 50, provider)       otro módulo compite, con un thunk
         └── resolve()                       corre el provider ganador, memoiza
               ├── devuelve algo  -> ese es el ganador
               └── lanza o da nil -> se marca como fallido y baja al siguiente
```

Los providers son **thunks**: funciones que devuelven la implementación. Corren
como máximo una vez, en el primer uso. Eso es lo que permite que una
implementación haga `require("telescope.builtin")` sin forzar la carga del
plugin en el arranque — y es la razón de que pasar `vim.lsp.buf.definition`
como argumento sea un error, porque eso resuelve `vim.lsp.buf` ahí mismo y se
lleva ~7 ms de arranque por una key que quizá no pulses nunca
([`lua/modules/core/keys.lua:19`](../lua/modules/core/keys.lua)).

Un thunk que lanza se descarta y gana el siguiente hacia abajo, hasta el nativo.
Un plugin roto degrada el editor, no lo rompe.

Tres kinds:

| kind | Qué resuelve | Ejemplo |
|---|---|---|
| `callable` | una función que se invoca | `goto.definition`, `finder.files` |
| `value` | un dato | `lsp.capabilities`, `docs.root` |
| `state` | algo que se aplica una vez | `syntax.engine`, `docs.render`, el colorscheme |

`:Dohwa features` y `:checkhealth dohwa` muestran, para cada feature, quién
gana ahora mismo y quién perdió.

## Dónde no poner cosas

- **No en `init.lua`.** Solo los leaders y el arranque. Cualquier otra cosa
  evita el arbitraje del broker y la validación del modelo de keys.
- **No en un `require` de otro módulo.** Si necesitas algo de otro módulo, es un
  feature: `ctx:value()` para un dato, `ctx:call()` para una acción,
  `ctx:has()` solo para decidir si ofrecer algo.
- **No `vim.keymap.set` directo** para mappings globales: el broker no podría
  detectar la colisión. Las excepciones son los mappings locales de buffer que
  instala el propio módulo en un autocommand, y los que instala un plugin por su
  cuenta — estos últimos se declaran con `ctx:external()` para que entren en la
  detección de colisiones y salgan en `:Dohwa keys`.
- **No estado dentro del módulo** entre arranques. Lo que debe sobrevivir a un
  reinicio lo escribe `Profile:set()` en el archivo de estado.

## Para seguir

- [kernel.md](kernel.md) — qué hace cada archivo de `lua/dohwa/`.
- [modules/core.md](modules/core.md) — los módulos protegidos, que son el suelo.
- [guides/adding-a-module.md](guides/adding-a-module.md) — la receta completa.
- [glossary.md](glossary.md) — el vocabulario, si alguna palabra de aquí te ha
  sonado a hueco.
