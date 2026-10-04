# El kernel

Dieciséis archivos en `lua/dohwa/`, 2.228 líneas, y ninguno sabe nada de ningún
plugin. Una sección por archivo: su responsabilidad, su API y la **invariante**
que protege — porque casi todas estas piezas existen para impedir una clase
concreta de error, y leerlas sin saber cuál es da la impresión de que sobra
maquinaria.

Desde cualquier archivo del kernel, `<leader>hm` te trae a su sección.

Requerir los dieciséis archivos cuesta 3,9 ms; `discover` + `graph:resolve` +
`keys:commit` juntos, 1,4 ms. El kernel no es el coste de esta configuración
([performance.md](performance.md)).

## init

El objeto maestro, `Dohwa`. Deliberadamente pequeño: posee la tabla de módulos,
el graph, el registry, el broker y la secuencia de boot, y nada más. Las
opciones, los mappings, los autocommands y los plugins viven todos en módulos,
incluidos los de `core/` y el propio loader.

```lua
require("dohwa"):boot()     -- init.lua; devuelve una única instancia
```

| API | Hace |
|---|---|
| `discover()` | Cada `lua/modules/**/*.lua` es un módulo y su ruta es su nombre. Elige la clase: `core.*` es `CoreModule`, con `plugins` es `PluginModule`. |
| `boot(opts)` | Los ocho pasos descritos en [architecture.md](architecture.md#el-boot-paso-a-paso). Idempotente: una segunda llamada no hace nada. |
| `disable(name, force)` / `enable(name)` | Persisten la decisión, revocan features y keys, y dicen qué dependía del módulo. |
| `why(name)` | Estado, razón, `requires`, `optional`, quién lo necesita, si está protegido. |
| `log(source, level, message)` | Todo lo que va mal se acumula aquí en vez de lanzarse. `:Dohwa log`. |
| `context(module)` | Un `Context` por módulo, memoizado. |

**Invariante: un módulo roto no aborta el arranque.** `discover` envuelve cada
`require` en `pcall`, `Module:run` convierte un error en estado `error` del
módulo, y `_collect_specs` reporta el conflicto entre un `config()` del spec y
un `setup()` del módulo en vez de resolverlo en silencio (`init.lua:206`).

## object

El sistema de clases mínimo que usa todo lo demás. `Base:extend("Nombre")` crea
una subclase y llamar a la clase la instancia: `local g = Graph()`.

El detalle que no es obvio: los metamétodos se buscan en la metatabla, nunca a
través de `__index`, así que `extend` los copia hacia abajo explícitamente
(`object.lua:26`). Sin eso, `__tostring` dejaría de funcionar en las subclases.

**Invariante: la cadena de herencia es inspeccionable.** `is_a()` la recorre, y
el kernel la usa para distinguir un `CoreModule` de un `Module` sin mirar el
nombre.

## module

Una unidad conmutable de configuración. Un módulo es una **declaración**, nunca
un script imperativo: expone cuatro hooks, y cuáles corren es lo que hace que
apagarlo sea seguro.

| Hook | Cuándo corre |
|---|---|
| `native(ctx)` | Siempre, mientras el módulo esté activo. Declara features con su nativo, reserva el namespace, ata keys. |
| `declare(ctx)` | Solo si los plugins se van a instalar. Registra las implementaciones mejores, como thunks. |
| `plugins(ctx)` | Datos puros para el loader. |
| `setup(ctx)` | Dentro del `config()` del propio plugin, así que sigue siendo lazy. |

Tres clases: `Module`, `CoreModule` (protegido por defecto, todo lo de
`modules/core/`) y `PluginModule` (aporta specs).

**Invariante: un hook que lanza no se propaga.** `Module:run` lo atrapa y deja
el módulo en estado `error` con la razón, que es lo que luego imprime
`:Dohwa status`.

## feature

Una capacidad con nombre y varias implementaciones ordenadas por prioridad. Esta
única abstracción cubre tres cosas que normalmente son tres mecanismos
distintos: los native fallbacks (prioridad 0), los slots de keys globales (un
feature al que una key está atada) y las capacidades cruzadas entre módulos
(`lsp.capabilities`).

| API | Hace |
|---|---|
| `implement(owner, priority, provider)` | Inserta y reordena. Empate de prioridad: gana el nombre de dueño menor, para que el resultado sea determinista. |
| `resolve()` | Corre el provider ganador y memoiza. Si lanza o devuelve nil, lo marca fallido y baja al siguiente. |
| `call(...)` / `activate()` | Invocar un `callable`; aplicar un `state` una sola vez. |
| `winner()` / `losers()` | Quién manda y quién quedó debajo — lo que imprime `:Dohwa features`. |
| `revoke(owner)` | Quita las implementaciones de un dueño (al deshabilitarlo en caliente). |

**Invariante: siempre hay suelo.** El nativo pertenece a quien declaró el
concepto, así que revocar a cualquier otro dueño nunca deja el feature vacío.
Un feature sin ninguna implementación y sin `optional` es un `orphan feature` y
`:checkhealth dohwa` lo marca como error.

## registry

Todos los features del sistema, más la contabilidad que hace visible el mal uso
en vez de silenciarlo.

| API | Hace |
|---|---|
| `declare(owner, name, opts)` | Declarar dos veces el mismo feature es un error registrado, no una excepción. |
| `implement(owner, name, ...)` | Implementar un feature no declarado crea un **placeholder**, marcado como `declared = false`. |
| `value(name, default)` / `call(name, ...)` | Leer un dato; invocar una acción. |
| `activate_states()` | Aplica todos los `state` al final del boot y devuelve los que fallaron. |
| `undeclared()` | Los placeholders que nunca recibieron declaración. |

**Invariante: un nombre mal escrito aparece, no desaparece.** El placeholder es
lo que permite que `tools.finder` implemente `docs.browse` sin conocer a
`tools.docs` (regla 3), y la lista de `undeclared()` es lo que impide que esa
libertad se convierta en features fantasma: `:checkhealth dohwa` avisa de cada
uno con dos posibles causas, el módulo apagado o la errata.

## keybroker

Propiedad y arbitraje de **todas** las keys de la configuración. Es el archivo
más grande del kernel (458 líneas) y el que sostiene la regla 2.

| API | Hace |
|---|---|
| `reserve(owner, prefix, desc, opts)` | Propiedad exclusiva de un prefijo. Dos reservas del mismo prefijo solo chocan si sus modos se solapan: `[` en insert y `[` en normal son namespaces distintos. |
| `claim(owner, modes, lhs, rhs, opts)` | Mapear a una implementación concreta, dentro del namespace propio. |
| `slot(owner, modes, lhs, feature, opts)` | Atar una key a un **feature**: se resuelve en el momento de pulsarla, así que manda quien gane entonces. |
| `toggle` / `jump` / `textobject` | Una letra en un namespace compartido; el segundo que la pida recibe un rechazo con el nombre del primero. |
| `commit()` | Valida el modelo completo en tres pasadas y aplica lo que sobrevive. |
| `release(owner)` | Suelta todo lo de un módulo y vuelve a arbitrar, para que un prefijo liberado quede disponible. |
| `groups(only_groups)` / `list(prefix)` / `conflicts()` | La introspección que consumen which-key, el listado nativo y checkhealth. |

Las tres pasadas de `commit()` (`keybroker.lua:255`): **1)** regla de namespace
por modo — una claim `external` se la salta, porque no se aplica aquí y no hay
nada que proteger; **2)** construir los tries y buscar duplicados y shadows;
**3)** aplicar. Un duplicado tiene ganador y el perdedor no se aplica; un shadow
se aplica igual y solo se reporta, porque es latencia, no un conflicto de
propiedad.

**Invariante: nada llega a `vim.keymap.set` sin que el modelo completo esté
validado.** Y al re-commitear, las keys aplicadas antes se borran primero
(`commit` empieza con un `vim.keymap.del` por cada una), para que deshabilitar
en caliente no deje mappings zombis.

### keytrie

Un trie de secuencias de keys, uno por modo. Es lo que hace visibles los dos
problemas interesantes: el duplicado exacto y el **prefix shadow** — un nodo que
es terminal e interno a la vez, como `<leader>f` mapeado existiendo también
`<leader>ff`. Neovim se queda esperando en la corta hasta que expira
`timeoutlen`. Esa clase de bug es invisible en una configuración normal, y es
exactamente la que mordió a `<leader>f` aquí.

`tokenize` parte `<leader>ff` en `{ "<leader>", "f", "f" }` y pasa los tokens
entre ángulos a minúsculas, para que `<Leader>` y `<leader>` colisionen.

## graph

El DAG de dependencias sobre nombres de módulo, con dos tipos de arista y
semánticas deliberadamente distintas:

- **`requires` (dura)** — la que falta deshabilita al dependiente, y el efecto
  cascadea transitivamente. Es lo que mantiene la integridad.
- **`optional` (blanda)** — no deshabilita nunca. Solo restringe el orden de
  declaración, para que una capacidad esté registrada antes de que un consumidor
  la busque.

`resolve(enabled)` cascadea en bucle hasta que ningún módulo más pierde una
dependencia dura, y luego ordena con Kahn. Los nombres se ordenan en cada paso,
así que el orden no depende del hash de Lua: dos arranques idénticos dan el
mismo orden.

**Invariante: un ciclo de aristas opcionales no es un ciclo.** Si el sort falla,
se reintenta ignorando las opcionales (`graph.lua:88`); si así sale, el arranque
continúa y se registra el `[info] optional dependency cycle broken`. Es el
mensaje que ves en `:Dohwa log` por `editor.lsp` ↔ `tools.finder`, que se
declaran mutuamente opcionales. No es un bug.

`dependents(name)` solo sigue aristas duras: es la respuesta a "qué se rompe si
quito esto", y la que imprime `:Dohwa disable`.

## context

El handle que recibe un módulo. Todo lo que un módulo puede tocar pasa por aquí,
**etiquetado con su nombre**, y de ahí viene la propiedad: features, keys y
grupos de autocommands son todos atribuibles y revocables.

| Grupo | Métodos |
|---|---|
| Features | `declare` · `implement` · `override` · `feature` · `call` · `value` |
| Keys | `reserve` · `map` · `slot` · `toggle` · `jump` · `textobject` · `external` · `revoke_keys` |
| Neovim | `augroup` · `autocmd` · `opt` |
| Introspección | `has` · `groups` · `mappings` · `log` · `warn` · `ui` |

`ctx:override(name)` merece una nota: dice "me hago cargo de este `state`",
registrando un no-op a prioridad 50. Es como un módulo anula el nativo sin
sustituirlo por nada, porque el plugin ya lo hace desde su propio `setup()`.
`editor.syntax` lo usa con `syntax.engine` y `tools.docs` con `docs.render`.

**Invariante: nada es anónimo.** `ctx:augroup()` devuelve `dohwa.<módulo>`, así
que los autocommands de un módulo se pueden borrar como unidad.

## profile

Qué está encendido, y dónde se recuerda. Dos capas, y el orden de precedencia
importa:

```
DOHWA_DISABLE=a,b        un arranque, sin tocar ningún archivo   (la más fuerte)
estado JSON              lo que escribió :Dohwa disable
lua/profiles/<n>.lua     la configuración que versionas
spec.default             qué pasa con un módulo que no está listado
```

El archivo de estado vive en `stdpath("state")/dohwa/<profile>.json`, así que
`:Dohwa disable tools.git` sobrevive al reinicio sin editar Lua y sin ensuciar
el repositorio. `Profile:loader()` deja que `DOHWA_LOADER` gane siempre.

**Invariante: un profile que no existe no impide arrancar.** Se registra el
error y se usa el spec por defecto (`default = true`, `loader = "lazy"`).

## loader

Cómo llegan los plugins al runtimepath. Es una **interfaz**, para que lazy.nvim
sea una implementación entre otras en vez de el cimiento de la configuración.

El contrato de `install(specs)`: el loader recibe los specs y es responsable de
que el `setup(ctx)` del módulo dueño corra una vez su plugin esté cargado. Un
loader que no instala nada simplemente no los llama nunca, y cada feature se
queda en el nativo que registró `native(ctx)`.

`installs_plugins()` es la pregunta que el boot hace en el paso 5: si es `false`,
`declare` no corre para los módulos con plugins.

### loader/lazy

lazy.nvim. Clona el repo en el primer arranque, lo prepende al runtimepath y le
pasa los specs. Mantiene el lockfile y la carga por eventos; Dohwa solo decide
*qué* specs recibe. También desactiva cinco plugins de distribución
(`gzip`, `tarPlugin`, `tohtml`, `tutor`, `zipPlugin`).

### loader/null

Ningún plugin. Es el test de aceptación de todo el diseño, no una curiosidad:
con `DOHWA_LOADER=null` cada módulo conserva sus features pero solo existen las
implementaciones de prioridad 0, así que lo que queda es el editor que Neovim
puede ser por sí solo. Si eso no es usable, falta un fallback.

`init.lua:9` lo fuerza cuando corres como root, por lo que un `sudo nvim` nunca
ejecuta código de plugins.

## command

`:Dohwa <subcomando>`, la superficie de control del sistema de módulos. Cada
subcomando es una función que construye líneas y las manda a `popup.show`, más
completado de subcomandos y de nombres de módulo.

| Subcomando | Muestra |
|---|---|
| `status` | loader, profile, ms de boot, y cada módulo con su marca (`+` activo, `-` deshabilitado, `~` saltado, `!` error) |
| `graph` | el orden topológico con las dependencias de cada módulo, y los saltados con su razón |
| `features` | cada feature: kind, ganador y contendientes |
| `keys [prefijo]` | los namespaces y todos los mappings aplicados, con su dueño |
| `log` | todo lo que `Dohwa:log` acumuló en el arranque |
| `why <módulo>` | el informe de `Dohwa:why` |
| `enable` / `disable [--force]` | persiste la decisión; `--force` para los protegidos |

## popup

Una ventana flotante de scratch para la salida de Dohwa, con `q` y `<Esc>` para
cerrar. Cuarenta líneas, sin dependencias: es el motivo de que `:Dohwa keys`
siga funcionando con which-key apagado.

## health

`:checkhealth dohwa`. El graph de módulos, el arbitraje de features y todas las
keys que el broker rechazó, en un solo sitio. Cinco secciones: `modules`,
`load order`, `features`, `keys` y `log` (esta última solo si hay algo).

Es el lugar donde los errores que el kernel decidió no lanzar se vuelven
visibles, y por eso cada aviso lleva una sugerencia: un orphan feature dice
"declara un native fallback", un feature no declarado dice "o el módulo está
apagado, o el nombre tiene una errata", y un shadow dice cuántos milisegundos
vale `timeoutlen` ahora mismo.

## Para seguir

- [architecture.md](architecture.md) — las tres reglas y el boot.
- [modules/core.md](modules/core.md) — lo que el kernel orquesta.
- [troubleshooting.md](troubleshooting.md) — cuando una de estas invariantes se
  queja.
