# Añadir un feature

Un feature es una capacidad con nombre y varias implementaciones ordenadas por
prioridad. Crear uno es lo que convierte "instalé un plugin" en "esta
configuración sabe hacer X, mejor o peor según lo que haya instalado".

Antes de escribir nada, dos preguntas.

## ¿Hace falta un feature?

No lo necesitas si el plugin no aporta ninguna capacidad que alguien pudiera
querer de otra forma. `ts-comments.nvim` mejora el `commentstring` que `gc` ya
usa: no hay nada que declarar.

Lo necesitas si la respuesta a cualquiera de estas es sí:

- ¿Quiero que una key siga funcionando con el plugin apagado?
- ¿Hay más de una forma razonable de hacer esto?
- ¿Otro módulo necesita este dato o esta acción?
- ¿Esto se aplica una vez, al arrancar, y solo debe aplicarlo uno?

## Elegir el kind

| kind | Resuelve a | Se usa con | Ejemplos |
|---|---|---|---|
| `callable` | una función | `ctx:call(name, ...)` o un `slot` | `goto.definition`, `finder.files`, `git.blame_line` |
| `value` | un dato cualquiera | `ctx:value(name, default)` | `lsp.capabilities`, `docs.root`, `git.diffstat` |
| `state` | una función que se aplica **una vez**, en el paso 8 del boot | nada: el registry la invoca | `ui.colorscheme`, `syntax.engine`, `format.on_save` |

El error típico es usar `callable` para algo que en realidad es `state`. La
prueba: si al cambiar de ganador habría que *deshacer* lo que hizo el anterior,
es `state`, y el nuevo dueño tiene que hacer `ctx:override(name)` en vez de
competir, porque los dos no pueden aplicarse a la vez.

## Quién lo declara

**El dueño del concepto**, y hay dos patrones, los dos legítimos:

```lua
-- A) lo declara quien lo provee: el caso normal
-- tools/docs.lua
ctx:declare("docs.root", {
  kind = "value",
  desc = "Where the documentation lives",
  native = function() return root() end,
})

-- B) lo declara quien lo CONSUME, como optional: cuando el dato puede no existir
-- ui/statusline.lua
ctx:declare("git.diffstat", {
  kind = "value",
  desc = "Added/changed/removed line counts",
  optional = true,
})
```

El patrón B es el que hace que la statusline no necesite saber si `tools.git`
existe: declara lo que quiere leer, y si nadie lo implementa, `ctx:value`
devuelve `nil` y la sección no se dibuja. `editor.lsp` hace lo mismo con
`lsp.capabilities`, pero **sin** `optional`, porque ahí sí hay un nativo
razonable (`vim.lsp.protocol.make_client_capabilities()`).

Declarar el mismo feature dos veces es un error registrado, no una excepción:
`:checkhealth dohwa` lo muestra con los dos dueños.

## Escribir el native floor

Esta es la parte que decide si el feature sirve para algo. Va en `native`, con
`opts.native`, y es un **thunk**: una función que *devuelve* la implementación.

```lua
ctx:declare("explorer.open", {
  desc = "Open the file explorer",
  native = function()           -- el thunk
    return function()           -- la implementación
      vim.cmd.Explore()
    end
  end,
})
```

Las dos capas no son ceremonia. El thunk corre como máximo una vez, en el primer
uso, así que es el sitio donde un `require` es gratis hasta que alguien usa la
key de verdad.

Tres patrones de native floor, con ejemplos reales:

```lua
-- 1. Degradar con elegancia: el LSP si hay servidor, el comando de Vim si no.
native = function()
  return function()
    if has_lsp() then
      vim.lsp.buf.definition()
    else
      vim.cmd("normal! gd")     -- normal! no recursa en nuestro propio slot
    end
  end
end

-- 2. Decirlo en vez de fingir, cuando no hay equivalente.
native = function()
  return function()
    if not has_lsp() then
      return vim.notify("no language server attached", vim.log.levels.WARN)
    end
    vim.lsp.buf.code_action()
  end
end

-- 3. No declarar nativo en absoluto: optional = true.
ctx:declare("git.preview_hunk", { desc = "Preview hunk", optional = true })
```

El tercero solo es legítimo cuando Neovim **de verdad** no puede hacerlo.
`tools.git` lo usa para los hunks porque no hay seguimiento de hunks nativo. Si
lo usas por comodidad, estás creando un orphan feature en potencia y la matriz
lo va a encontrar.

## Implementar

En `declare`, con prioridad 50 por convención, y siempre como thunk:

```lua
declare = function(ctx)
  ctx:implement("explorer.open", 50, function()
    return function()
      require("oil").open()     -- el require vive AQUÍ, dentro del thunk
    end
  end)
end
```

Prioridades: **0** es el nativo y no se toca. **50** es un plugin. Usa otra cosa
solo si dos plugins pueden competir por el mismo feature y quieres fijar el
orden; en empate gana el nombre de dueño alfabéticamente menor, así que el
resultado es determinista pero arbitrario.

Para un `value`, el thunk devuelve el dato directamente:

```lua
ctx:implement("lsp.capabilities", 50, function()
  return require("cmp_nvim_lsp").default_capabilities()
end)
```

Para un `state` que el plugin ya maneja, no implementes: **override**.

```lua
ctx:override("syntax.engine")   -- un no-op a 50: "me hago cargo de esto"
```

## Atar una key, si la lleva

Un feature y una key son cosas distintas, y mantenerlas separadas es la regla 2:

```lua
-- dentro de tu propio namespace:
ctx:reserve("<leader>e", "Explorer")
ctx:slot("n", "<leader>e", "explorer.open")

-- o deja que lo haga core.keys, si es una key global
-- (entonces tú solo implementas el feature y nunca mencionas la key)
```

## Consumir uno

```lua
ctx:call("diagnostic.next")                              -- callable
local caps = ctx:value("lsp.capabilities", <fallback>)   -- value, con fallback
```

**Siempre con fallback** en los `value`: el módulo que lo implementaba puede
estar apagado. Y nunca guardes el resultado en un local del módulo durante
`native`, porque eso resuelve el feature antes de que todos hayan declarado.

## Qué pasa cuando algo falla

Nada explota, y conviene saber exactamente qué ocurre:

| Fallo | Consecuencia |
|---|---|
| el thunk lanza | se marca fallido, gana el siguiente hacia abajo, hasta el nativo |
| el thunk devuelve `nil` | igual: se trata como fallo |
| nadie implementa y no es `optional` | **orphan feature**: `:checkhealth dohwa` lo marca como error |
| implementas un nombre mal escrito | placeholder `declared = false`, listado en checkhealth como *implemented but never declared* |
| declaras dos veces | error registrado con los dos dueños |

## Verificar

```bash
nvim --headless "+checkhealth dohwa" +qa
```

Busca tu feature en la sección `features`. Lo que quieres ver:

```
explorer.open            tools.explorer:50 (over tools.explorer:0)
```

Y después, la prueba de verdad:

```bash
DOHWA_LOADER=null nvim        # ¿tu feature sigue haciendo algo útil?
scripts/matrix.sh null
```

## Para seguir

- [../architecture.md](../architecture.md#el-ciclo-de-vida-de-un-feature) — el
  ciclo completo.
- [../kernel.md](../kernel.md#feature) — la mecánica de la arbitración.
- [changing-keys.md](changing-keys.md) — atar keys a lo que acabas de declarar.
