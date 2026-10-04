# Añadir un lenguaje

Un lenguaje nuevo toca tres módulos, y ninguno sabe de los otros dos: servidor
en `editor.lsp`, formateador en `editor.format`, parser en `editor.syntax`. Los
tres pasos son independientes y cada uno sirve de algo por sí solo.

Como ejemplo: **Go**.

## 1. El servidor (editor.lsp)

Una entrada en la tabla `M.servers` de
[`lua/modules/editor/lsp.lua`](../../lua/modules/editor/lsp.lua). Esa tabla la
leen **los dos caminos**, el nativo y el de los plugins, así que con esto solo
ya tienes LSP funcionando incluso con `DOHWA_LOADER=null`:

```lua
gopls = {
  cmd = { "gopls" },
  filetypes = { "go", "gomod", "gowork", "gotmpl" },
  root_markers = { "go.work", "go.mod", ".git" },
  settings = {
    gopls = {
      analyses = { unusedparams = true },
      staticcheck = true,
      hints = { parameterNames = true },
    },
  },
},
```

Los cuatro campos y por qué importan:

| Campo | Para qué |
|---|---|
| `cmd` | cómo arrancarlo. `cmd[1]` es también lo que se comprueba con `vim.fn.executable()`: un servidor cuyo binario no está no se registra, porque habilitarlo haría que Neovim fallara al lanzarlo |
| `filetypes` | en qué buffers se engancha |
| `root_markers` | qué marca la raíz del proyecto |
| `settings` | lo que el servidor espera en su `workspace/configuration` |

**Instalarlo.** Dos opciones, y las dos funcionan:

```
:MasonInstall gopls         # queda en stdpath("data")/mason/bin, que está en el PATH
```

o el gestor de paquetes del sistema. `add_mason_to_path()` corre antes de
registrar, así que el camino nativo encuentra los dos.

`mason-lspconfig` recibe `ensure_installed = vim.tbl_keys(M.servers)`, así que
tu entrada nueva entra en esa lista automáticamente y Mason lo instalará solo en
el siguiente arranque. Cuando la instalación acabe —es asíncrona, mucho después
de `BufReadPre`— un hook de `mason-registry` vuelve a registrar los servidores,
pero **no se engancha a los buffers ya abiertos**: `vim.lsp.enable()` solo actúa
sobre eventos `FileType` posteriores. Abre otro archivo, o reinicia.

**Si sirve inlay hints y ya hay otro servidor para esos filetypes**, añádelo a
`hint_priority`. Dos servidores sirviendo hints en el mismo buffer rompen el
decorador de Neovim con `Invalid 'col': out of range`; el guard de
`guard_inlay_hints()` solo deja pasar al de mayor prioridad. Un lenguaje con un
único servidor no necesita tocar nada: lo no listado vale 50.

Comprobar:

```
:checkhealth vim.lsp      # cliente enganchado, root dir, capabilities
:Dohwa features           # lsp.servers y quién lo gana
```

## 2. El formateador (editor.format)

Dos sitios, porque hay dos caminos, y los dos se mantienen a mano:

```lua
-- camino nativo: la tabla PROGRAMS, que apunta 'formatprg'
local PROGRAMS = {
  lua = { "stylua -" },
  go = { "gofmt" },        -- nuevo
  ...
}
```

```lua
-- camino conform: formatters_by_ft, en el spec del plugin
formatters_by_ft = {
  lua = { "stylua" },
  go = { "goimports", "gofmt", stop_after_first = true },   -- nuevo
  ...
}
```

Las dos listas se recorren buscando el **primer programa que de verdad esté
instalado** (`vim.fn.executable` en el nativo, `stop_after_first` en conform), así
que poner varios candidatos no cuesta nada.

Si el formateador necesita el nombre del archivo para decidir —como prettier—,
añádelo a `PRETTIER_FILETYPES` en vez de a `PROGRAMS`: esos se resuelven por
buffer, no por filetype.

Comprobar:

```
:set formatprg?           # en un buffer de Go: gofmt
<leader>==                # formatea
:ConformInfo              # qué formateador usaría conform
```

Con `editor.format` apagado, `<leader>==` sigue formateando: `format.buffer` cae
a su nativo, que usa `'formatprg'` o el LSP.

## 3. El parser (editor.syntax)

Una entrada en `ensure_installed`, en
[`lua/modules/editor/syntax.lua`](../../lua/modules/editor/syntax.lua):

```lua
ensure_installed = {
  "c", "cpp", "lua", "vim", "vimdoc", "bash",
  "go", "gomod", "gosum",     -- nuevo
  ...
},
```

Con `auto_install = true` esto es casi redundante —el parser se instala al abrir
el primer archivo del lenguaje— pero tenerlo en la lista explícita es lo que
hace que una instalación nueva lo traiga de entrada.

Si quieres text objects estructurales para el lenguaje, no hay nada más que
hacer: las queries vienen con el parser, y los mappings (`af`, `if`, `]f`…) ya
están declarados de forma genérica.

Comprobar:

```
:InspectTree              # el árbol sintáctico del buffer
:Inspect                  # los grupos de highlight bajo el cursor
```

Sin el módulo, el lenguaje cae al motor regex de Vim, que para Go significa
resaltado razonable y ningún text object.

## 4. Lo que casi siempre se olvida

| Cosa | Dónde |
|---|---|
| El filetype no se detecta | `vim.filetype.add` — ningún módulo lo hace hoy; iría en `core.options` si fuera necesario |
| Indentación distinta | `core.options` pone `shiftwidth = 4` global; Go quiere tabs, y eso lo arregla el parser con `indent = { enable = true }` o un autocommand `FileType` propio |
| El linter | No hay módulo de linting en esta configuración. La mayoría de los servidores LSP ya diagnostican; si hace falta más, es un módulo nuevo |
| El debugger | Tampoco. Sería `editor.debug`, con native floor… ninguno, así que todos sus features `optional = true`, como los hunks de git |

## Verificar el conjunto

```bash
nvim --headless "+Lazy! sync" +qa
nvim --headless "+checkhealth dohwa" +qa
scripts/matrix.sh lazy
scripts/matrix.sh null
```

Y a mano, lo que de verdad importa: abre un archivo del lenguaje y comprueba las
cuatro cosas por separado —resaltado, `gd`, `<leader>==`, los diagnósticos— una
vez con todo encendido y otra con `DOHWA_LOADER=null`. La segunda vez tienen que
funcionar tres de las cuatro.

## Para seguir

- [../modules/editor.md](../modules/editor.md) — los tres módulos en detalle.
- [adding-a-plugin.md](adding-a-plugin.md) — si el lenguaje necesita un plugin
  propio.
- [../troubleshooting.md](../troubleshooting.md) — "el LSP no se engancha".
