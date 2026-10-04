# Añadir un plugin a un módulo existente

No todo plugin merece un módulo. Esta guía es para cuando lo que quieres añadir
cae dentro de algo que ya existe.

## Decidir: módulo nuevo o spec en uno existente

| Señal | Decisión |
|---|---|
| Aporta una capacidad que nadie tiene todavía | módulo nuevo |
| Quieres poder apagarlo por separado | módulo nuevo |
| Es una fuente, un adaptador o un tema de otro plugin | spec en el módulo que lo usa |
| Solo funciona si el otro plugin está cargado | `dependencies` de ese spec |
| Compite por un feature que ya existe | depende: si quieres elegir entre los dos, módulo nuevo; si sustituye al otro, cambia el spec |

La prueba práctica: **¿tiene sentido `:Dohwa disable` solo para esto?** Si la
respuesta es no, es un spec, no un módulo.

Ejemplos de la configuración actual: las seis fuentes de nvim-cmp, LuaSnip y
friendly-snippets son `dependencies` de un solo spec, porque sin cmp no hacen
nada. mason y mason-lspconfig son specs **hermanos** dentro de `editor.lsp`, no
dependencias, porque tienen su propio trigger (`VeryLazy`) y su propio coste.

## Añadir una dependencia

Lo más sencillo. En el `plugins` del módulo:

```lua
plugins = function()
  return {
    {
      "hrsh7th/nvim-cmp",
      event = { "InsertEnter", "CmdlineEnter" },
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        -- el nuevo:
        "hrsh7th/cmp-cmdline",
      },
    },
  }
end
```

Y, si hace falta, úsalo en `setup`. Nada más: no entra en el graph de Dohwa, no
tiene estado propio y no se puede apagar por separado. Eso es correcto para una
fuente de completion.

## Añadir un spec hermano

Cuando el plugin tiene su propio momento de carga:

```lua
plugins = function(ctx)
  return {
    {
      "neovim/nvim-lspconfig",
      dohwa_main = true,          -- este lleva el config() del módulo
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "williamboman/mason.nvim",
      event = "VeryLazy",          -- su propio trigger, su propio coste
      cmd = { "Mason", "MasonInstall" },
      opts = { ... },
    },
  }
end
```

**`dohwa_main = true` es obligatorio aquí.** Un módulo que define `setup` es
dueño del `config()` de su spec principal, y el kernel elige como principal el
primero de la lista salvo que uno lleve esa marca
([`lua/dohwa/init.lua:201`](../../lua/dohwa/init.lua)). Si el orden cambia y no
hay marca, el `setup()` del módulo se engancha al spec equivocado y corre en el
momento equivocado.

## El conflicto `config()` contra `setup()`

Esta es la trampa que el kernel detecta y reporta:

```
[error] editor.lsp: spec defines config() and the module defines setup(); setup() wins
```

Pasa cuando el spec principal trae su propio `config` **y** el módulo define
`setup`. El kernel no lo resuelve en silencio: sobrescribe el `config` con el
`setup` del módulo y lo registra en `:Dohwa log`.

Las dos formas correctas:

```lua
-- A) el módulo lleva la configuración: usa setup(), y el spec no lleva config ni opts
setup = function(ctx)
  require("mi-plugin").setup(OPTS)   -- la tabla, en un local del archivo
end

-- B) el spec lleva la configuración: usa opts o config, y el módulo NO define setup
plugins = function()
  return { { "owner/repo", event = "VeryLazy", opts = { ... } } }
end
```

Un spec **hermano** sí puede llevar su propio `config` sin conflicto: el aviso
solo mira el principal. `mason-lspconfig` en `editor.lsp` lo usa así.

**Si defines `setup`, no pases `opts`.** lazy.nvim ya no te lo aplica, porque el
`config()` que lo haría es ahora el tuyo. Guarda la tabla en un local del
archivo y pásala tú — mira `OPTS` en
[`lua/modules/editor/pairs.lua`](../../lua/modules/editor/pairs.lua).

## Elegir el trigger de carga

Por orden de preferencia, y la razón:

| Trigger | Cuándo | Ejemplo |
|---|---|---|
| `lazy = true` sin evento | el plugin solo se usa desde un feature. El broker es dueño de las keys y lazy.nvim engancha `require`, así que carga en la primera llamada de verdad | telescope |
| `ft = { ... }` | solo sirve para ciertos filetypes | render-markdown |
| `event = "BufReadPre"` | tiene que estar antes de que se lea el buffer | lspconfig, gitsigns |
| `event = "InsertEnter"` | solo actúa en modo insert | cmp, autopairs |
| `event = "VeryLazy"` | hace falta en algún momento, pero no antes de que se dibuje la pantalla | which-key, mason |
| `lazy = false` | se ve en pantalla desde el primer frame | temas, statusline |

**El error que más cuesta** es poner un plugin en un evento más temprano de lo
necesario. Mason colgado de lspconfig costaba 8 ms en *cada archivo abierto*;
moverlo a `VeryLazy` no cambió nada funcional. Y lo contrario: telescope sin
ningún trigger cargaba en el arranque y era el plugin más caro de la
configuración.

Antes y después, siempre medido:

```bash
nvim --headless --startuptime /tmp/st.log algún-archivo.lua +qa && tail -1 /tmp/st.log
DOHWA_DISABLE=<módulo> nvim --headless --startuptime /tmp/st2.log algún-archivo.lua +qa
```

Siete repeticiones y la mediana: la varianza de arranque ronda los 3 ms, así que
una sola medición no dice nada.

## Si el plugin aporta una capacidad

Entonces no basta con el spec: declara o implementa un feature. Eso está en
[adding-a-feature.md](adding-a-feature.md). La regla corta: si quieres poder
apagarlo y que algo siga funcionando, hace falta un feature con native floor.

## Si el plugin trae keys

Dos posibilidades:

- **Las instala él mismo** desde su `setup()` → decláralas con
  `ctx:external(modes, lhs, desc)` en `declare`. No se aplican, pero entran en la
  detección de colisiones y salen en `:Dohwa keys`.
- **Las quieres tú** → `ctx:reserve` + `ctx:map`/`ctx:slot` en `native`, dentro
  del namespace del módulo. Ver [changing-keys.md](changing-keys.md).

Nunca `keys = { ... }` en el spec de lazy.nvim: eso esquiva al broker y el
mapping queda fuera del arbitraje.

## Verificar

```bash
nvim --headless "+Lazy! sync" +qa
nvim --headless "+checkhealth dohwa" +qa    # sin errores nuevos en la sección log
scripts/matrix.sh lazy
```

Y en `:Dohwa log`, que no haya aparecido el aviso de `config()` contra `setup()`.

## Para seguir

- [adding-a-module.md](adding-a-module.md) — si al final sí era un módulo.
- [adding-a-feature.md](adding-a-feature.md) — darle una capacidad conmutable.
- [../performance.md](../performance.md) — las mediciones que justifican cada
  trigger.
