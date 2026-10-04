# Rendimiento

Todas las cifras de esta página están medidas en esta máquina, con
`--startuptime`, **mediana de 9 arranques**. La varianza entre repeticiones ronda
los 3 ms, así que trátalas como la forma del coste y no como números exactos:
cualquier diferencia por debajo de 3 ms es ruido.

La columna que importa en el día a día no es el arranque en vacío, sino la de
abrir un archivo: `BufReadPre` y `BufReadPost` es donde ocurre casi todo el
trabajo.

## El panorama

| | vacío | abriendo un `.lua` |
|---|---|---|
| `nvim --clean` (suelo) | 7,7 ms | 16,3 ms |
| dohwa, cero plugins (`DOHWA_LOADER=null`) | 24,5 ms | 33,5 ms |
| dohwa, los 15 módulos | 32,6 ms | 55,1 ms |

Los 8 ms entre `--clean` y el camino nativo son la configuración en sí: opciones,
autocommands, 48 features declarados y 118 mappings validados y aplicados. Los
~22 ms siguientes son los plugins.

## Coste por módulo

Apagando cada uno por turnos con `DOHWA_DISABLE` y abriendo un `.lua`. El coste
es la diferencia contra los 55,1 ms de referencia:

| Módulo | Coste |
|---|---|
| `editor.lsp` (lspconfig) | 7,6 ms |
| `editor.syntax` (tree-sitter) | 6,0 ms |
| `ui.statusline` (lualine) | 4,0 ms |
| `ui.theme` (gruvbox) | 2,4 ms |
| `tools.git` (gitsigns) | 1,7 ms |
| `ui.hints` (which-key) | 0,3 ms |
| `tools.finder`, `tools.docs`, `editor.complete`, `editor.pairs`, `editor.format` | por debajo de la varianza |

Los cinco últimos no cuestan nada al abrir un archivo porque **no cargan al abrir
un archivo**: telescope carga en la primera llamada real, cmp y autopairs en la
primera entrada a modo insert, conform al primer guardado, y render-markdown solo
en buffers markdown.

Esos costes diferidos, medidos aparte:

| Coste diferido | Cuándo | Cuánto |
|---|---|---|
| telescope | primera invocación de la sesión | ~12 ms más que las siguientes |
| cmp + autopairs | primera entrada a insert, una vez por sesión | 28 ms juntos |
| render-markdown | primer `.md` de la sesión | 23,6 ms (84,7 contra 61,1) |

## El kernel no es el coste

Es la cosa más fácil de suponer al ver 16 archivos de kernel y 48 features, y es
falsa:

| Pieza | Coste |
|---|---|
| requerir los 16 archivos del kernel | 2,0 ms |
| `discover` + `graph:resolve` + `keys:commit` | 1,4 ms |
| `boot()` completo, con los `native` de los 15 módulos | 20,4 ms |
| dispatch de un feature (la indirección en cada pulsación) | por debajo de la resolución del temporizador |

El último merece una explicación: atar una key a un feature en vez de a una
función significa una llamada extra —`registry:call(name)` → `Feature:resolve()`
memoizado → la función— en cada pulsación. **LuaJIT la compila entera.** No se
puede medir, y por eso la regla 2 sale gratis.

De los 20,4 ms de `boot()`, la mayoría son los `native(ctx)` de los módulos: las
opciones, los 11 servidores de LSP registrados en el camino nativo, los
autocommands. El kernel orquesta; los módulos trabajan.

## Las decisiones tomadas por medición

Todo lo que sigue se cambió porque una medición lo pidió, no porque pareciera
mejor.

### No añadir `vim.loader.enable()`

Parece gratis y no lo es. lazy.nvim ya instala una caché de módulos Lua, y
añadir una segunda capa midió **más lento**: 70,9 ms contra 68,3 ms de mediana
sobre 15 arranques.

### Mason va en `VeryLazy`, no colgado de lspconfig

Mason es un instalador: su única contribución en runtime es una entrada de
`PATH`, que `add_mason_to_path()` hace nativamente en tres líneas. Tenerlo como
`dependencies` de nvim-lspconfig arrastraba mason.nvim (1,4 ms),
mason-lspconfig (6,5 ms) y mason-registry a **cada archivo abierto**, para nada:
8 ms de peaje permanente por una comodidad que se usa una vez al mes.

`VeryLazy` dispara después de dibujar la pantalla, así que el coste deja de
sentirse. La lista `cmd` mantiene `:Mason` funcionando si ese evento no llega
nunca.

### El módulo Lua de nvim-lspconfig nunca se requiere

Neovim 0.12 lee sus 418 archivos `lsp/*.lua` directamente del runtimepath, así
que el plugin actúa como un **directorio de datos**, no como código. De ahí que
su spec no tenga dependencias y que el módulo registre los servidores con
`vim.lsp.config()` y `vim.lsp.enable()` nativos.

### Telescope sin ningún evento

El broker es dueño de todos los mappings y lazy.nvim engancha `require`, así que
telescope es `lazy = true` **sin trigger alguno**: carga la primera vez que un
feature llama de verdad a su código. Antes este spec no tenía ni `lazy` ni
evento y cargaba en el arranque, lo que lo convertía en el plugin más caro de la
configuración.

Es el patrón general: con el arbitraje de keys centralizado, un plugin que solo
se usa desde features no necesita trigger.

### La statusline no busca la raíz del repositorio en cada redraw

`branch()` lee la rama de `.git/HEAD`, y la caché se consulta **antes** de
`vim.fs.root`, no después. Localizar la raíz significa hacer `stat()` de cada
directorio hasta `/`: 12,9 µs, **el 70 % del coste de renderizar la
statusline**, y estaba corriendo en cada redraw. La caché dura 2 segundos por
directorio.

### `vim.lsp.enable()` no se engancha a buffers ya abiertos

Solo actúa sobre eventos `FileType` posteriores. Eso **no** es una optimización,
es una restricción: obliga a registrar los servidores desde `setup()` sobre
`BufReadPre` y no se puede mover más tarde. Es también la razón de que una
instalación de Mason que termina a mitad de sesión no engancha el servidor hasta
que abres otro archivo.

## Cómo medir un cambio

```bash
S=/tmp/st
for i in $(seq 1 9); do
  nvim --headless --startuptime $S.log algún-archivo.lua +qa
  grep "NVIM STARTED" $S.log | tail -1 | awk '{print $1}'
done | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]" ms (mediana)"}'
```

Y para aislar un módulo, lo mismo con `DOHWA_DISABLE=<módulo>` delante. Dos
avisos:

- **Nueve repeticiones como mínimo.** Con tres, la varianza de 3 ms te hace ver
  mejoras que no existen.
- **Mide abriendo un archivo real**, no en vacío. La mitad de los plugins no
  cargan hasta que hay un buffer.

Para ver *dentro* del arranque:

```bash
nvim --headless --startuptime /tmp/st.log algún-archivo.lua +qa && sort -k2 -rn /tmp/st.log | head -20
:Lazy profile      # el desglose de lazy.nvim, plugin por plugin
:Dohwa status      # la línea boot: los ms de boot() en esta sesión
```

## Para seguir

- [modules/editor.md](modules/editor.md) — el grupo que concentra el coste.
- [kernel.md](kernel.md) — qué hacen esos 20 ms de boot.
- [guides/adding-a-plugin.md](guides/adding-a-plugin.md) — elegir el trigger de
  carga, que es la decisión que más pesa.
