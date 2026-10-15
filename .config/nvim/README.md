# Configuración de Neovim

Una config de [lazy.nvim](https://github.com/folke/lazy.nvim) sin framework
propio: 23 plugins, ~1.100 líneas de Lua. Cada archivo hace una cosa y se lee
de arriba abajo.

Requiere Neovim 0.12 o superior: `vim.lsp.config()`, `vim.lsp.enable()` y
`vim.treesitter.foldexpr()` son nativos y la config los usa directamente.

## Estructura

```
init.lua                 leaders, requires, arranque de lazy.nvim
lua/core/
  registry.lua           qué plugins están habilitados (lo lee init.lua)
  utils.lua              mecanismos compartidos: defer(), buffmapper(), augroup(),
                         notify_state(), toggle_wo()
lua/config/
  options.lua            opciones del editor y presentación de diagnósticos
  keymaps.lua            keys globales que no pertenecen a ningún plugin
  autocmds.lua           autocomandos del editor
  servers.lua            qué servidores LSP se arrancan y con qué ajustes
lua/keyaudit/            :KeyAudit y :checkhealth keyaudit
lua/plugins/             un plugin por archivo, configurado dentro
  autopairs.lua          nvim-autopairs
  cmp.lua                nvim-cmp, LuaSnip y sus fuentes
  conform.lua            formateo
  gitsigns.lua           señales de git en la columna de signos
  gruvbox.lua            colorscheme
  lspconfig.lua          arranque de los servidores, keys del LSP
  lualine.lua            statusline
  mason.lua              instalador
  mason_lspconfig.lua    instala lo que declara config/servers.lua
  render_markdown.lua    render de markdown en el buffer
  telescope.lua          búsqueda difusa
  treesitter.lua         resaltado, indentación, text objects
  which_key.lua          pistas de teclas
```

**Un plugin por archivo.** El nombre del archivo es el del plugin en minúsculas,
sin guiones ni puntos (`which_key.lua`, `render_markdown.lua`), y cada archivo
devuelve un único spec con todo dentro: su `opts`, sus keys, sus iconos y su
borde. No hay un módulo de tokens compartido: el borde `single` y los iconos
están escritos en cada archivo, así que cambiar el borde de toda la config es
buscar `"single"`. La única excepción es `config/servers.lua`, porque la tabla de
servidores la leen dos plugins (uno los arranca, el otro los instala).

**El esqueleto de un archivo de plugin.** Los 13 tienen la misma forma, en este
orden y sin excepciones:

```lua
--- <qué es y por qué está acá>
local u = require("core.utils")      -- 1. requires

local icons = { ... }                -- 2. datos locales
local settings = { ... }

local builtin = u.defer("mod")       -- 3. helpers locales
local function on_attach(buf) ... end

return {                             -- 4. el spec: tabla plana
  "autor/plugin",
  event = "...",
  opts = { ... },
}
```

Reglas: después del `return` no hay nada; dentro del spec no hay lógica, solo datos y
un `config`/`opts` que llama a los locals de arriba; `opts` como tabla siempre que se
pueda. Los iconos y el borde se escriben en cada archivo como datos — eso no vuelve a un
módulo compartido.

**El vocabulario compartido** está en `lua/core/utils.lua`, para usarse en esos locals:

- `utils.defer(mod)` devuelve un constructor de callbacks diferidos. `local builtin =
  utils.defer("telescope.builtin")` y después `builtin("find_files", { cwd = ... })`
  guarda el `require` y la llamada para cuando se pulse la tecla. Es lo que mantiene a
  Telescope descargado hasta el primer uso.
- `utils.buffmapper(buf)` devuelve el `map(mode, lhs, rhs, desc)` local al buffer, para
  los `on_attach` del LSP y de gitsigns.
- `utils.augroup(name)` crea el grupo `config.<name>` con `clear = true`.
- `utils.toggle_wo(name)` devuelve el callback que invierte una opción de ventana y
  avisa; `utils.notify_state(label, on)` es solo el aviso, para los toggles que
  consultan su estado por otra API. Los siete `<leader>t*` de `config/keymaps.lua`
  salen de estos dos.

La regla para que ese módulo no crezca de más: entra solo lo que tiene dos o más usos
reales. Con un solo sitio de llamada se escribe inline — el `require("conform").format({...})`
de `plugins/conform.lua` es más claro así que pasando por un helper. Y ahí no entra
apariencia: es mecanismo, no estilo.

**Habilitar y apagar plugins.** `lua/core/registry.lua` es la lista autoritativa:
`init.lua` la pasa como `spec`, y comentar una línea apaga el plugin de verdad
(desaparece de `:Lazy`). No se usa `{ import = "plugins" }` porque ese import barre el
directorio *además* de leer la lista, y entonces un plugin comentado seguiría cargando.
El costo es que agregar un plugin son dos ediciones, su archivo y su línea; un archivo
que no esté en el registro no carga y no avisa, y de eso se encarga
`:checkhealth keyaudit`, que compara la lista con el directorio.

**Dónde poner una key.** Si solo tiene sentido con un plugin cargado, va en el
`keys = {}` de ese plugin: así el plugin se carga en el primer uso. Si es del
LSP, va en el `LspAttach` de `plugins/lspconfig.lua`, que la hace local al buffer. El
resto va en `config/keymaps.lua`.

**Apagar algo** es comentar su línea en `lua/core/registry.lua` (o `enabled = false`
en su spec, si querés dejarlo visible en `:Lazy`).

## Keys

El líder es `<Space>`.

### Búsqueda — `<leader>f`

| Key | Qué hace |
|---|---|
| `<leader>ff` | Archivos del proyecto |
| `<leader>fg` | Buscar texto (live grep) |
| `<leader>fw` | Buscar la palabra bajo el cursor |
| `<leader>fb` | Buffers abiertos |
| `<leader>fr` | Archivos recientes |
| `<leader>fh` | Manual de Neovim |
| `<leader>fd` | Diagnósticos |
| `<leader>fc` | Archivos de esta config |
| `<leader>/` | Buscar dentro de este archivo |

`<leader>Ff`, `<leader>Fg` y `<leader>Fb` son los equivalentes nativos
(`:find`, `:grep`, `:buffer`). Se conservan porque `:find` entiende `path` y
`wildignore`, que a veces es justo lo que quieres.

### LSP

Locales al buffer: en un archivo sin servidor, `gd` y `K` conservan su
significado nativo.

| Key | Qué hace |
|---|---|
| `gd` | Ir a la definición |
| `gD` | Ir a la declaración |
| `gr` | Referencias |
| `gi` | Implementaciones |
| `gt` | Definición de tipo |
| `gO` / `<leader>cs` | Símbolos del documento |
| `K` | Documentación flotante |
| `<C-s>` (inserción) | Ayuda de firma |
| `<leader>ca` | Code actions |
| `<leader>cr` | Renombrar símbolo |

### Diagnósticos — `<leader>d`

`<leader>dd` el del cursor · `<leader>dl` la lista · `]d` / `[d` saltar.

### Git — `<leader>g`

`<leader>gp` preview del hunk · `<leader>gd` diff del archivo ·
`<leader>gb` blame de la línea · `<leader>gr` resetear hunk ·
`<leader>gR` resetear archivo · `]h` / `[h` saltar entre hunks ·
`ih` / `ah` el hunk como text object.

### Toggles — `<leader>t`

`w` wrap · `d` diagnósticos · `n` números relativos · `s` corrector ·
`h` inlay hints · `f` formato al guardar · `m` render de markdown ·
`b` blame en línea.

### Estructura (tree-sitter)

`af`/`if` función · `ac`/`ic` clase · `aa`/`ia` parámetro ·
`ai`/`ii` condicional · `al`/`il` bucle.
`]f`/`[f` función · `]C`/`[C` clase · `]a`/`[a` parámetro.
`<C-space>` ampliar la selección, `<BS>` reducirla.
`<leader>sa` / `<leader>sA` intercambiar parámetros.

### Formato

`<leader>==` formatear el buffer. Al guardar se formatea solo, salvo que
`<leader>tf` lo haya desactivado.

### Otras

`<Esc>` quita el resaltado de búsqueda · `<C-h/j/k/l>` moverse entre ventanas ·
`J`/`K` en visual mueven la selección · `<C-d>`/`<C-u>` y `n`/`N` centran ·
`<leader>??` muestra las keys disponibles.

## Decisiones que no son obvias

Si vas a tocar algo, estas son las que te morderán.

**Los mapeos `gr*` se borran al arrancar.** Neovim 0.11 trae `grn`, `gra`,
`grr`, `gri` y `grt`. Esta config mapea `gr`, así que cada uno de ellos
esperaría `timeoutlen`. Se borran en `config/keymaps.lua` antes de mapear `gr`.

**`:KeyAudit` detecta ese tipo de bug.** Un mapeo que es a la vez
secuencia completa y prefijo de otra espera `timeoutlen`, así que el editor
"va lento" sin que nada lo reporte. Lee `nvim_get_keymap()` ya aplicado, así que
ve también los mapeos que instalan los plugins y los de Neovim. Hoy encuentra
uno: `gc` es prefijo de `gcc`, ambos de Neovim. Es benigno — `gc` necesita un
movimiento de todas formas — pero sale en el informe.

**Los inlay hints llevan un guard** (`plugins/lspconfig.lua`). Neovim guarda una lista
de hints por cliente pero un único `version` para todo el buffer, y una
notificación de cambio solo refresca al cliente que la envió. Con dos servidores
que sirven hints en el mismo buffer (`.vue`: `ts_ls` y `vue_ls`), el que
responde más tarde marca el estado como actual mientras las columnas del otro
apuntan a líneas que ya se acortaron, y el decorador muere con
`Invalid 'col': out of range`. El guard descarta toda respuesta que no sea del
cliente propietario del buffer.

**nvim-lspconfig no tiene `dependencies`, a propósito.** Neovim 0.12 lee sus
`lsp/*.lua` del runtimepath y nunca requiere su módulo Lua, así que el plugin es
un directorio de defaults, no código. Mason es un instalador, no una dependencia
de ejecución: tenerlo ahí arrastraba mason.nvim, mason-lspconfig y
mason-registry a cada archivo abierto, para nada.

**Solo se habilitan los servidores instalados.** Mason está diferido a
`VeryLazy`, así que no se puede asumir que ya ha corrido; habilitar un servidor
cuyo binario no existe hace que Neovim falle al lanzarlo. El `bin` de Mason se
añade al `PATH` primero, para encontrar lo que instaló en sesiones anteriores.

**Las directivas de tree-sitter se re-registran** (`plugins/treesitter.lua`).
Neovim 0.12 quitó `set-lang-from-info-string!` y `downcase!`, que la rama master
de nvim-treesitter sigue emitiendo. Sin esto se rompen las inyecciones en
markdown.

**Sin el binario `tree-sitter`, algunas gramáticas se excluyen.** Unas pocas
(latex, swift, teal…) deben regenerarse con la CLI; sin ella el instalador
aborta dentro del autocomando y Neovim lo reporta como
`Error in BufReadPost Autocommands`.

**`]c` / `[c` siguen siendo las motions de diff.** La navegación de hunks de
gitsigns cede cuando `vim.wo.diff` está activo.

**`<CR>` pertenece a nvim-cmp.** nvim-autopairs lleva `map_cr = false`; si los
dos lo mapean, confirmar un completado inserta además un salto de línea.

**Los highlights de nvim-cmp se re-enlazan tras `ColorScheme`.** Están enlazados
a grupos de tree-sitter en vez de a colores fijos; sin el autocomando, el menú
pierde el color la primera vez que cambia el tema.

## Mantenimiento

```bash
:Lazy          # estado de los plugins
:Lazy profile  # qué cuesta cada uno al arrancar
:Mason         # instalar servidores y formateadores
:KeyAudit      # buscar prefix shadows
:checkhealth   # salud general
```

`lazy-lock.json` fija las versiones. `:Lazy restore` vuelve a ellas,
`:Lazy update` las mueve.
