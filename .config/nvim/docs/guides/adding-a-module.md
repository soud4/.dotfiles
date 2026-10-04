# Añadir un módulo

Cada plugin de esta configuración es un módulo, y también lo es todo lo que no
es un plugin. Este es el procedimiento para añadir uno sin romper las tres
reglas sobre las que descansa el diseño: un native floor para todo, ninguna
colisión de keys entre módulos, y ningún módulo que referencie a otro.

Un módulo es `lua/modules/<grupo>/<nombre>.lua`. Su ruta es su nombre, así que
`tools/git.lua` es `tools.git`. No hay índice que actualizar ni nada que
registrar: dejar el archivo ahí *es* el registro, y el profile lo enciende por
defecto.

## Paso 0: clasificar el plugin

Tres preguntas, y las respuestas deciden cuántos hooks escribes.

| Pregunta | Si no | Si sí |
|---|---|---|
| ¿Trae keys? | solo `plugins` | + `reserve` y `slot`/`map` en `native` |
| ¿Neovim ya hace algo parecido? | sin Feature | + `declare` de un Feature con su `native` |
| ¿Sustituye o alimenta a otro módulo? | — | + `implement`/`value` sobre un Feature existente |

La segunda es la que importa, y la respuesta es "sí" más a menudo de lo que la
gente espera. Antes de dar por hecho que no hay native floor, comprueba:
`gc`/`gcc` para comentarios (incorporado desde 0.10), netrw para navegar
archivos, `vim.ui.open`, `vim.ui.select`, `vim.snippet`, `vim.lsp.*`,
`vim.treesitter.*`, `:grep` al quickfix, `'formatprg'`.

## Los cuatro hooks

```lua
return {
  description = "Una línea",
  requires = {},   -- dura: si falta una, este módulo se deshabilita, transitivamente
  optional = {},   -- blanda: solo ordena, nunca deshabilita nada

  -- SIEMPRE, mientras el módulo esté activo, incluso con DOHWA_LOADER=null.
  -- Declara Features con su implementación nativa, reserva el namespace de
  -- keys, ata keys.
  native = function(ctx) end,

  -- SOLO cuando los plugins se vayan a instalar de verdad. Registra las
  -- implementaciones mejores, como thunks. Nunca hagas require() de un plugin
  -- aquí.
  declare = function(ctx) end,

  -- Datos puros para el loader.
  plugins = function(ctx) return { { "owner/repo", event = "..." } } end,

  -- Corre dentro del config() del propio plugin, así que sigue siendo lazy.
  setup = function(ctx) end,
}
```

La separación entre `native` y `declare` es lo que hace que apagar un módulo sea
seguro. Con el null loader, o cuando un módulo se salta porque le falta una
dependencia dura, `declare` y `setup` no corren nunca y todos sus Features se
quedan en su implementación de prioridad 0.

## Caso A: el plugin simplemente funciona

Sin keys y sin ninguna capacidad que le importe a nadie más.
`folke/ts-comments.nvim` solo mejora el `commentstring` que el `gc`
incorporado ya usa, así que el native floor es Neovim mismo y no hay nada que
declarar.

`lua/modules/editor/comments.lua`:

```lua
--- Better commentstring for embedded languages.
---
--- Native floor: Neovim's own gc/gcc, built in since 0.10. This module only
--- teaches it about embedded languages, so switching it off costs accuracy in
--- JSX and Vue, not the ability to comment.
return {
  description = "Comment string via tree-sitter",
  optional = { "editor.syntax" },

  plugins = function()
    return {
      {
        "folke/ts-comments.nvim",
        event = "VeryLazy",
        opts = {},
      },
    }
  end,
}
```

Ese es el módulo entero. Sin `native`, sin `declare`, sin `setup`.

## Caso B: trae una key y tiene equivalente nativo

`stevearc/oil.nvim` es un explorador de archivos, y Neovim trae netrw.

`lua/modules/tools/explorer.lua`:

```lua
--- File explorer.
---
--- Native floor: netrw, which ships with Neovim. <leader>e opens whichever
--- explorer is in charge, so disabling this module changes which one appears
--- and nothing else.
return {
  description = "File explorer",

  native = function(ctx)
    ctx:declare("explorer.open", {
      desc = "Open the file explorer",
      native = function()
        return function()
          vim.cmd.Explore()
        end
      end,
    })

    ctx:reserve("<leader>e", "Explorer")
    ctx:slot("n", "<leader>e", "explorer.open")
  end,

  declare = function(ctx)
    ctx:implement("explorer.open", 50, function()
      return function()
        require("oil").open()
      end
    end)
  end,

  plugins = function()
    return {
      {
        "stevearc/oil.nvim",
        -- No trigger: the broker owns the key, and lazy.nvim hooks require(),
        -- so oil loads the first time the feature is actually called.
        lazy = true,
        opts = { view_options = { show_hidden = true } },
        dependencies = { "nvim-tree/nvim-web-devicons" },
      },
    }
  end,
}
```

Fíjate en lo que **no** hay: ningún `pcall(require, "oil")`, ningún
`if has_oil then`, y ningún trigger de carga. Lo que compra:

- `DOHWA_LOADER=null nvim` — `<leader>e` abre netrw.
- `:Dohwa disable tools.explorer` — la key desaparece, nada más cambia.
- `:checkhealth dohwa` — `explorer.open  tools.explorer:50 (over tools.explorer:0)`.

### Keys globales de un solo carácter

`oil.nvim` usa `-` por convención. Una reserva de un carácter en un modo
concreto es legítima — `editor.pairs` hace exactamente esto con `(` en modo
insert:

```lua
ctx:reserve("-", "Explorer", { modes = { "n" } })
ctx:slot("n", "-", "explorer.open")
```

A partir de ahí, cualquier otro módulo que pida `-` en modo normal es rechazado
por su nombre.

## Caso C: alimenta o sustituye a otro módulo

Nunca con `require`. Siempre por Features, y en los dos sentidos:

```lua
-- CONSUMIR lo que otro módulo publique, con un fallback para cuando esté off:
local capabilities = ctx:value("lsp.capabilities", vim.lsp.protocol.make_client_capabilities())

-- PUBLICAR para quien lo quiera, sin saber quién es:
ctx:implement("git.diffstat", 50, function()
  return function()
    return { added = 3, changed = 1, removed = 0 }
  end
end)

-- HACERSE CARGO de un state feature que el plugin maneja desde su setup():
ctx:override("syntax.engine")
```

Implementar un Feature que nadie declaró crea un placeholder opcional y lo
marca: `:checkhealth dohwa` lo lista bajo *implemented but never declared*, que
es la forma que tiene un nombre mal escrito. Si simplemente el módulo que lo
declara está apagado, no pasa nada más.

## Cinco cosas con las que se tropieza

1. **Si defines `setup`, no pases `opts`.** Ese módulo pasa a ser dueño del
   `config()` de su spec principal, así que lazy.nvim ya no te aplica `opts`.
   Guarda la tabla en un local y pásala tú — mira `OPTS` en
   `lua/modules/editor/pairs.lua`.
2. **`dohwa_main = true`** en el spec que deba llevar el `config()`, cuando no
   es el primero de la lista. `lua/modules/editor/lsp.lua` lo usa.
3. **Nunca hagas `require()` de un plugin en `native` ni en `declare`.** Solo
   dentro del thunk que devuelve la implementación, o en `setup`. Esto es lo que
   preserva el lazy loading.
4. **Los mappings que el plugin instala por su cuenta** van por
   `ctx:external(modes, lhs, desc)`. No se aplican, pero entran en la detección
   de colisiones y salen en `:Dohwa keys`. Sin esto son invisibles — el agujero
   que tenían nvim-treesitter-textobjects y gitsigns.
5. **Los namespaces compartidos reparten una letra por módulo:**
   `ctx:toggle(letra, ...)` para `<leader>t`, `ctx:jump(letra, ...)` para
   `]`/`[`, `ctx:textobject(letra, ...)` para `a`/`i`. El segundo que la pida es
   rechazado, nombrando a los dos módulos.

## La API de Context

Todo lo que un módulo puede tocar, etiquetado con su nombre para que la
propiedad nunca sea ambigua. Definida en `lua/dohwa/context.lua`.

| Método | Para qué |
|---|---|
| `ctx:declare(name, opts)` | declarar un Feature; `opts.native` es el suelo a prioridad 0 |
| `ctx:implement(name, priority, provider)` | registrar una implementación mejor, como thunk |
| `ctx:override(name)` | suprimir el native floor porque el plugin ya se encarga |
| `ctx:call(name, ...)` / `ctx:value(name, default)` | usar un Feature |
| `ctx:reserve(prefix, desc, opts)` | reclamar un namespace de keys; `opts.modes` lo estrecha |
| `ctx:map(modes, lhs, rhs, opts)` | mapear dentro de tu namespace |
| `ctx:slot(modes, lhs, feature, opts)` | atar una key a un Feature |
| `ctx:toggle` / `ctx:jump` / `ctx:textobject` | tomar una letra en un namespace compartido |
| `ctx:external(modes, lhs, desc)` | declarar un mapping que instala el plugin |
| `ctx:augroup(suffix)` / `ctx:autocmd(event, opts)` | autocommands con namespace |
| `ctx:opt(table)` | poner opciones |
| `ctx:has(module)` | si otro módulo está activo |
| `ctx.ui` | los tokens visuales compartidos de `lua/core/ui.lua` |

## Verificar

Después de añadir cualquier módulo, en este orden:

```bash
nvim --headless "+Lazy! sync" +qa          # instalar
nvim --headless "+checkhealth dohwa" +qa   # 0 rejected, 0 shadowed, 0 orphan features
./scripts/matrix.sh lazy                   # apagar cada módulo por turnos
./scripts/matrix.sh null                   # y otra vez sin ningún plugin
DOHWA_LOADER=null nvim                     # el camino nativo a mano: ¿sigue siendo usable?
```

Qué buscar en `:checkhealth dohwa`: el Feature nuevo mostrando
`módulo:50 (over módulo:0)`, el namespace nuevo en el recuento, y
`no rejected mappings` intacto. Si la matriz falla cuando tu módulo nuevo está
deshabilitado, uno de sus Features le falta la implementación nativa.

## Para seguir

- [removing-a-module.md](removing-a-module.md) — la mitad inversa, con la
  cascada de dependencias.
- [adding-a-plugin.md](adding-a-plugin.md) — cuando no hace falta un módulo
  nuevo.
- [adding-a-feature.md](adding-a-feature.md) — elegir kind, prioridad y native
  floor.
- [changing-keys.md](changing-keys.md) — namespaces, letras y los tres rechazos.
