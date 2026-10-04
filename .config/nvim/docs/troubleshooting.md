# Solución de problemas

Organizado por **síntoma**, no por componente: cuando algo va mal no sabes
todavía de qué pieza es. Cada entrada dice qué mirar, con qué comando, y qué
deberías ver.

Los cuatro comandos que resuelven casi todo:

```
:checkhealth dohwa   el informe completo, con sugerencias
:Dohwa status        los 15 módulos y su estado
:Dohwa log           lo que pasó en el arranque
:Dohwa why <módulo>  por qué ese módulo está como está
```

## Una key no hace nada

**1. ¿Está aplicada?**

```
:Dohwa keys <leader>f
```

Si no aparece, no está aplicada. Mira los rechazos:

```
:checkhealth dohwa
```

- `namespace violation` → el módulo mapea fuera de su reserva. Ver
  [guides/changing-keys.md](guides/changing-keys.md).
- `duplicate mapping` → otro módulo ganó esa secuencia; el mensaje nombra al
  dueño.
- `reservation taken` / `toggle letter taken` → dos módulos querían el mismo
  prefijo o la misma letra.

**2. Si aparece pero no hace nada**, es un slot cuyo feature no resuelve:

```
:Dohwa features
```

Busca la línea del feature. Un `—` en la columna del ganador significa **orphan
feature**: nadie lo implementa. Si el feature es `optional` eso es legítimo —los
hunks de git sin gitsigns, por ejemplo— y la key simplemente no hace nada.

**3. Si el feature tiene ganador pero la acción falla**, el thunk del ganador
está lanzando. `Feature:resolve()` lo descarta y baja al siguiente, así que
normalmente verás el comportamiento nativo en vez de un error. Fuerza el camino
nativo para confirmarlo:

```bash
DOHWA_LOADER=null nvim
```

## Una key tarda medio segundo

Es un **prefix shadow**: esa secuencia es también el prefijo de otra, así que no
dispara hasta que expira `timeoutlen` (400 ms aquí).

```
:checkhealth dohwa
```

```
n <leader>f (tools.finder) delays <leader>fb, <leader>fc, <leader>ff
  it only fires after 'timeoutlen' (400ms)
```

Las dos keys están aplicadas y funcionan: es latencia, no un conflicto. El
arreglo es mover la corta a dos caracteres, o quitarla.

Caso especial ya resuelto: Neovim 0.11 trae `grn`, `gra`, `grr`, `gri`, `grt`.
Como esta configuración mapea `gr`, `core.keys` los borra explícitamente. Si
vuelves a ver `gr` lento, comprueba que ese bucle sigue ahí
(`lua/modules/core/keys.lua:214`).

## Un plugin no carga nunca

Primero: **puede ser correcto**. Telescope no tiene trigger a propósito y carga
en la primera llamada real; render-markdown solo en buffers markdown.

```
:Lazy                       ¿está instalado? ¿cargado?
:Dohwa status               ¿su módulo está active?
:Dohwa features             ¿su implementación gana algún feature?
```

| Lo que ves | Causa probable |
|---|---|
| módulo `disabled` | el perfil, el archivo de estado o `DOHWA_DISABLE`. Mira la precedencia en [guides/profiles-and-disabling.md](guides/profiles-and-disabling.md) |
| módulo `skipped` | le falta una dependencia dura; la razón lo dice |
| módulo `error` | un hook lanzó. `:Dohwa log` tiene el mensaje |
| módulo `active` pero el plugin no carga | su trigger no ha ocurrido, o su implementación nunca se invoca |
| en `:Lazy` sale "not installed" | `nvim --headless "+Lazy! sync" +qa` |

Si el módulo es `active`, su plugin está instalado y aun así su implementación
no gana el feature, el thunk está lanzando al resolver. Eso sí es un bug, y
`:Dohwa features` lo delata: el ganador será el nativo con el plugin instalado.

## El LSP no se engancha

En orden, porque las causas son bastante distintas:

```
:checkhealth vim.lsp        clientes, root dir, capabilities
:Dohwa features             lsp.servers: ¿quién lo gana?
:LspInfo                    (si lspconfig está cargado)
```

| Síntoma | Causa |
|---|---|
| Ningún cliente en ningún archivo del lenguaje | el binario no está en el `PATH`. Solo se registran los servidores cuyo `cmd[1]` pasa `vim.fn.executable()` |
| Funciona en archivos nuevos, no en el que ya tenías abierto | **esperado.** `vim.lsp.enable()` solo actúa sobre eventos `FileType` posteriores; no se engancha a buffers ya abiertos. Reabre el archivo |
| Acaba de instalarse con Mason y no engancha | igual que lo anterior: la instalación es asíncrona y termina mucho después de `BufReadPre` |
| Engancha pero sin raíz de proyecto | faltan `root_markers`, o estás fuera de un proyecto |
| `Invalid 'col': out of range` al escribir | dos servidores sirviendo inlay hints en el mismo buffer. Añade el segundo a `hint_priority` en `lua/modules/editor/lsp.lua` |
| Sin completion del servidor | mira `completion.engine` en `:Dohwa features`; con `editor.complete` apagado, la completion nativa necesita `vim.lsp.completion.enable`, que el nativo engancha en `LspAttach` |

Con `editor.lsp` apagado los servidores **siguen arrancando** por el camino
nativo. Lo que pierdes es Mason y la detección de raíz de lspconfig.

## checkhealth dice "orphan feature"

```
features with no implementation at all: explorer.open
  declare a native fallback so disabling the module stays safe
```

Significa que una key o una llamada no hace absolutamente nada. Dos causas:

1. **El feature se declaró sin `native` y sin `optional`.** Es el caso normal, y
   el arreglo es escribir el native floor —ver
   [guides/adding-a-feature.md](guides/adding-a-feature.md)— o marcarlo
   `optional = true` si Neovim de verdad no puede hacerlo.
2. **El módulo que lo implementaba está apagado** y el declarante no puso nativo.
   Mismo arreglo.

`scripts/matrix.sh` existe para encontrar esto antes que tú: apaga cada módulo
por turnos y comprueba que no quedan orphans.

## checkhealth dice "implemented but never declared"

```
implemented but never declared: docs.browse
  either the declaring module is off, or the feature name is misspelled
```

Las dos causas del mensaje, y conviene distinguirlas:

- **Legítimo:** `tools.finder` implementa `docs.browse`, que declara
  `tools.docs`, y `tools.docs` está apagado. Nada que arreglar.
- **Una errata:** el nombre no coincide con ningún feature declarado. Compara
  con `:Dohwa features`, que lista todos los nombres reales.

## El arranque va lento

```
:Dohwa status                       la línea boot: los ms de boot()
:Lazy profile                       desglose por plugin
nvim --headless --startuptime /tmp/st.log archivo.lua +qa && sort -k2 -rn /tmp/st.log | head -20
```

Si `boot:` está por encima de ~25 ms, el problema está en un `native(ctx)` —y
casi siempre es un `require` que no debería estar ahí. La regla: **nunca
`require` de un plugin en `native` ni en `declare`**, solo dentro del thunk. Un
`require` en `declare` resuelve el módulo en el arranque y anula todo el lazy
loading.

El procedimiento completo, con las mediciones de referencia, está en
[performance.md](performance.md).

## El editor se comporta distinto como root

Es deliberado: `init.lua:9` fuerza `DOHWA_LOADER=null` cuando el uid es 0, así
que un `sudo nvim` nunca ejecuta código de plugins. Lo que ves es el native floor
entero, que es un editor completo con otro aspecto (`retrobox` en vez de
gruvbox, statusline nativa, `vim.ui.select` en vez de Telescope).

```
:Dohwa status      loader: null
```

## Un módulo está en estado `error`

```
:Dohwa status      la marca es !
:Dohwa log         el mensaje completo
```

La razón tiene la forma `native(): <error>`, porque `Module:run` atrapa el
error, lo guarda como estado y sigue. Causas habituales:

| Razón | Qué pasó |
|---|---|
| `could not be loaded: ...` | el archivo tiene un error de sintaxis o lanza al requerirse |
| `must return a table` | el módulo no devuelve su tabla de spec |
| `invalid spec: ... must be a function` | un hook no es una función |
| `native(): attempt to index a nil value` | un error dentro del hook |
| `spec defines config() and the module defines setup()` | conflicto de propiedad; ver [guides/adding-a-plugin.md](guides/adding-a-plugin.md) |

El resto de la configuración sigue arrancando: eso es a propósito, y es la razón
de que haya que mirar `:Dohwa status` de vez en cuando aunque todo *parezca* ir
bien.

## Después de tocar algo, siempre

```bash
nvim --headless "+checkhealth dohwa" +qa
scripts/matrix.sh lazy
scripts/matrix.sh null
```

La matriz es la prueba de verdad: apaga cada módulo por turnos y luego todos, y
comprueba que nada da error, que ningún feature no-opcional se queda sin
implementación, y que ninguna key fue rechazada.

## Para seguir

- [guides/changing-keys.md](guides/changing-keys.md) — los tres rechazos en
  detalle.
- [kernel.md](kernel.md#health) — qué comprueba cada sección de checkhealth.
- [glossary.md](glossary.md) — si un término del informe no te dice nada.
