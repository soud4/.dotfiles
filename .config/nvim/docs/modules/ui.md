# Módulos: ui

Los tres módulos de `lua/modules/ui/`: el tema, la statusline y las pistas de
keys. Es el grupo más pequeño y el que tiene la propiedad más curiosa: **los tres
tienen native floors completos y creíbles**, porque todo lo que hacen es
presentar información que la configuración ya tiene.

Los tokens visuales que comparten —el borde y los iconos— no están en ninguno de
los tres: están en [`lua/core/ui.lua`](../../lua/core/ui.lua), que se requiere
directamente porque hace falta mientras los módulos se están declarando. Se
llega a él desde cualquier módulo como `ctx.ui`.

## theme

[`lua/modules/ui/theme.lua`](../../lua/modules/ui/theme.lua) · 62 líneas

El esquema de color.

**Native floor.** `retrobox`, que viene con Neovim y es un gruvbox en todo menos
en el nombre. Apagar este módulo cambia ligeramente la paleta y nada más. El
nativo además pone a `none` el fondo de `Normal`, `NormalFloat`, `SignColumn` y
`EndOfBuffer`, para igualar el aspecto transparente que usa la configuración con
plugin.

**Features.** `ui.colorscheme` (state), declarado aquí con ese nativo e
implementado a 50 con gruvbox.nvim en modo `transparent_mode`.

Es un `state`, así que se aplica en el paso 8 del boot, cuando ya se sabe quién
ganó. Por eso el menú de completion, que enlaza sus colores a grupos de
tree-sitter y se re-enlaza en `ColorScheme`, acaba coherente sin que
`editor.complete` sepa qué tema hay.

**Keys.** Ninguna.
**Plugins.** gruvbox.nvim con `lazy = false` y `priority = 1000`: un tema tiene
que cargar antes que todo lo demás, o ves el cambio de paleta en pantalla.
**Coste.** 2–3 ms.
**Apagarlo.** `retrobox`. Es la degradación más suave de toda la configuración.

## statusline

[`lua/modules/ui/statusline.lua`](../../lua/modules/ui/statusline.lua) · 238 líneas

La statusline, con `laststatus=3` (una global) puesto en `core.options`.

**Native floor, y es una statusline de verdad, no un placeholder:** modo,
archivo con indicadores de modificado y solo-lectura, rama de git, cifras
+/~/−, diagnósticos por severidad, servidores LSP enganchados, directorio,
filetype y posición. Es lo que se ve cuando lualine no está instalado.

**Features.**

| Feature | Kind | Rol |
|---|---|---|
| `ui.statusline` | state | declarado aquí; el nativo apunta `vim.o.statusline` a `M.render()` por `v:lua`, y lualine lo gana a 50 |
| `git.diffstat` | value | **lo declara aquí el consumidor**, como `optional`. `tools.git` lo implementa leyendo `vim.b.gitsigns_status_dict`; sin él, las cifras simplemente no aparecen |

**Las dos configuraciones viven en el mismo archivo** a propósito:
`M.render()` para el camino nativo y `M.lualine_opts()` para el otro, una al lado
de la otra, para que las dos muestren la misma información en el mismo orden. Es
el archivo donde más fácil sería que las dos versiones divergieran.

**Un detalle medido.** `branch()` lee la rama directamente de `.git/HEAD`, y la
caché se consulta **antes** de `vim.fs.root`, no después. Localizar la raíz del
repositorio significa hacer `stat()` de cada directorio hasta `/`: 12,9 µs,
aproximadamente el 70 % del coste de renderizar la statusline, y estaba
corriendo en **cada redraw**. La caché vale 2 segundos por directorio.

**Keys.** Ninguna.
**Plugins.** lualine.nvim con `lazy = false` y nvim-web-devicons.
**Coste.** 4–6 ms.
**Apagarlo.** La statusline nativa, con la misma información. Pierdes los colores
por modo y los iconos de devicons.

## hints

[`lua/modules/ui/hints.lua`](../../lua/modules/ui/hints.lua) · 77 líneas

Las pistas de keys. Setenta y siete líneas, y es el módulo que mejor resume el
diseño entero.

**Ninguna de las dos implementaciones mantiene su propia lista de grupos.** Las
dos leen el **broker**, que ya sabe cada namespace y cada mapping con su
descripción y su dueño. Apagar un módulo hace que su grupo desaparezca de las
pistas por sí solo: el clásico `<leader>f` huérfano que se queda en which-key
después de quitar un plugin es algo que aquí no puede pasar.

Y va en los dos sentidos: el spec del plugin se construye *desde* las reservas
del broker, no se escribe otra vez.

```lua
plugins = function(ctx)
  local spec = {}
  for _, group in ipairs(ctx:groups(true)) do
    spec[#spec + 1] = { group.prefix, group = group.desc }
  end
  ...
```

**Features.** `hints.show` (callable): el nativo pregunta por un prefijo con
`vim.ui.input` y lista namespaces y mappings en el popup de `dohwa.popup`;
which-key lo gana a 50 con `show({ global = false })`.

**Keys.** Reserva `<leader>?` y mapea `<leader>??`. Dos signos de interrogación
porque el prefijo reservado no se mapea a sí mismo: eso sería un prefix shadow
contra sus propios hijos, exactamente lo que el broker reporta.

**Plugins.** which-key.nvim en `VeryLazy`, preset `helix` (panel lateral
compacto en vez de pantalla completa) y `delay = 500` — suficiente para
mantenerse fuera del camino cuando ya sabes la key.
**Apagarlo.** `<leader>??` sigue funcionando y sigue siendo correcto; pierdes el
panel automático al dudar sobre un prefijo.

## Para seguir

- [../kernel.md](../kernel.md#keybroker) — la introspección que consumen estos
  dos módulos.
- [core.md](core.md) — quién es dueño de los namespaces que las pistas listan.
- [../performance.md](../performance.md) — el coste de la statusline por redraw.
