# Plan de documentación

Qué se escribe, en qué orden, y con qué reglas. La configuración son ~5.200
líneas repartidas en un kernel de 13 archivos y 15 módulos: el problema no es
que falte información, sino que hoy está toda en comentarios dentro del código
y en un README que ya hace de resumen, de tutorial y de informe de rendimiento
a la vez.

El plan reparte esa carga en páginas con una pregunta cada una, y deja en manos
de un generador todo lo que la configuración ya sabe de sí misma.

## Principios

1. **Una página, una pregunta.** Si una página responde a dos, se parte.
2. **Lo que el config sabe, no se escribe a mano.** El mapa de keys, el árbol de
   dependencias y el catálogo de features salen del broker y del registry vía
   `scripts/gendoc.sh`. Escribir eso a mano garantiza que se desactualice.
3. **La documentación explica el *por qué*; el código ya dice el *qué*.** Los
   comentarios del fuente son buenos y se quedan donde están. Las páginas no los
   repiten: enlazan a `archivo:línea` y cuentan la decisión.
4. **Cada módulo se documenta por su superficie conmutable**, porque es lo que
   de verdad se consulta: qué se pierde al apagarlo, qué native floor queda, qué
   features declara y qué keys ocupa.
5. **Prosa en español, vocabulario del dominio en inglés.** *Feature*, *slot*,
   *thunk*, *native floor*, *broker*, *namespace* y los nombres de módulo se
   escriben como en el código. Traducirlos rompería el puente con el fuente.

## Estructura de archivos

```
docs/
  README.md                        índice y estado
  plan.md                          esta página
  architecture.md                  las tres reglas · object model · boot
  kernel.md                        una sección por archivo de lua/dohwa/
  glossary.md                      vocabulario
  troubleshooting.md               síntoma -> dónde mirar
  performance.md                   mediciones y decisiones
  modules/{core,editor,tools,ui}.md   una ficha por módulo
  guides/                          tareas concretas
    adding-a-module.md             (ya existe: se mueve aquí)
    removing-a-module.md
    adding-a-plugin.md
    adding-a-feature.md
    changing-keys.md
    adding-a-language.md
    profiles-and-disabling.md
  reference/                       GENERADO, no editar
    keys.md  features.md  dependencies.md  modules.md
```

## Contrato de los anchors

`<leader>hm` abre la documentación del archivo que estás editando, y para
encontrar la sección busca `^#\+\s\+.*\<nombre\>` desde la primera línea. Eso
impone tres reglas en las páginas de módulos y del kernel:

- La sección de un módulo se titula con **su nombre exacto**: `## lsp` en
  `modules/editor.md`, `## finder` en `modules/tools.md`.
- La sección de una pieza del kernel se titula con **el nombre del archivo sin
  extensión**: `## keybroker`, `## registry`, `## graph` en `kernel.md`.
- `lua/profiles/*.lua` apunta a `guides/profiles-and-disabling.md`, que no
  lleva anchor: el archivo entero es la respuesta. Lo resuelve
  `page_for_current_file()` en `lua/modules/tools/docs.lua`.

## Plantilla de ficha de módulo

Todas las fichas llevan los mismos apartados y en el mismo orden, para poder
comparar dos módulos de un vistazo:

```markdown
## <nombre>

Una línea: qué hace y para quién.

**Native floor.** Qué queda cuando el módulo se apaga o no hay plugins.
**Features.** Tabla: declara | implementa (con prioridad) | consume.
**Keys.** Tabla: lhs | modo | feature o acción | namespace.
**Plugins.** Lista con el trigger de carga (`event`, `ft`, `lazy = true`).
**Dependencias.** `requires` / `optional`, y quién lo necesita.
**Coste.** ms medidos, del apartado de rendimiento.
**Apagarlo.** `:Dohwa disable <nombre>` y qué se degrada exactamente.
```

## Fases

### Fase 0 — Lector de documentación · hecho

Módulo `tools.docs` (`lua/modules/tools/docs.lua`), namespace `<leader>h`:

| Key | Hace |
|---|---|
| `<leader>hh` | Selector de páginas (Telescope con preview; `vim.ui.select` sin él) |
| `<leader>hi` | Índice `docs/README.md` |
| `<leader>hg` | Buscar texto en la documentación |
| `<leader>hm` | Página del archivo que estás editando |
| `<leader>tm` | Activar/desactivar el renderizado de markdown |
| `:Docs <tab>` | Abrir una página por nombre, con completado |

Dentro de una página: `<CR>`/`gf` sigue el enlace, `<BS>` vuelve, `gO` muestra
el índice de la página, `q` cierra la pestaña. El renderizado lo hace
render-markdown.nvim sobre el feature `docs.render`; el native floor es
`conceallevel=2` más el `gO` que Neovim ya trae para markdown.

### Fase 1 — Índice y convenciones · hecho

`docs/README.md` y esta página. El índice lleva la tabla de estado, así que
hace también de checklist.

### Fase 2 — Arquitectura y kernel · hecho

`architecture.md` es la página que se lee primero y la única que puede ser
larga. Cubre:

- Las tres reglas y qué problema real resuelve cada una.
- El object model, con el árbol de `Object` y por qué los módulos son tablas
  declarativas y no clases.
- El boot en sus ocho pasos (`lua/dohwa/init.lua:88`), con el *por qué* de cada
  orden: natives antes que declare, validación completa del modelo de keys antes
  de aplicar nada, states al final.
- El ciclo de vida de un feature: `declare` → `implement` → `resolve` →
  memoización, y qué pasa cuando un thunk falla.
- Dónde **no** poner cosas: por qué `core/ui.lua` se requiere directamente en
  lugar de ser un módulo, y por qué nada llama a `require` de otro módulo.

`kernel.md`: una sección por archivo, ~15 líneas cada una, con su
responsabilidad, su API pública y la invariante que protege. Orden: `object`,
`module`, `feature`, `registry`, `keybroker`, `keytrie`, `graph`, `context`,
`profile`, `loader`, `command`, `popup`, `health`.

`glossary.md`: native floor, feature (callable/value/state), slot, thunk,
reservation, namespace compartido, external claim, prefix shadow, profile,
loader, protected module.

### Fase 3 — Módulos · hecho

Cuatro páginas, quince fichas, con la plantilla de arriba. Datos ya conocidos:

| Módulo | Líneas | Plugins | optional |
|---|---|---|---|
| `core.options` | 93 | — | — |
| `core.keys` | 297 | — | — |
| `core.autocmds` | 59 | — | — |
| `core.toggles` | 33 | — | — |
| `editor.lsp` | 390 | nvim-lspconfig, mason, mason-lspconfig | `editor.complete`, `tools.finder` |
| `editor.complete` | 200 | nvim-cmp + 4 fuentes, LuaSnip, friendly-snippets | — |
| `editor.format` | 136 | conform.nvim | — |
| `editor.pairs` | 142 | nvim-autopairs | `editor.complete`, `editor.syntax` |
| `editor.syntax` | 169 | nvim-treesitter (+textobjects) | — |
| `tools.finder` | 267 | telescope (+plenary, fzf-native, devicons) | `editor.lsp` |
| `tools.git` | 174 | gitsigns.nvim | — |
| `tools.docs` | 404 | render-markdown.nvim | `editor.syntax` |
| `ui.theme` | 62 | gruvbox.nvim | — |
| `ui.statusline` | 238 | lualine.nvim | — |
| `ui.hints` | 77 | which-key.nvim | — |

Dos cosas que hay que documentar aquí y que no son evidentes en el fuente:

- **`editor.lsp` y `tools.finder` se declaran mutuamente opcionales**, lo que
  forma un ciclo entre dependencias opcionales. El graph lo rompe y lo anuncia
  (`optional dependency cycle broken`), que es el `[info]` que aparece en
  `:Dohwa log` en cada arranque. Es correcto, y merece una nota para que nadie
  lo persiga como si fuera un bug.
- **`tools.finder` implementa `docs.browse` y `docs.grep`**, features que
  declara `tools.docs`. Es el patrón de placeholder del registry
  (`lua/dohwa/registry.lua:57`): ninguno de los dos módulos conoce al otro, se
  encuentran por el nombre del feature y por el `value` feature `docs.root`.

### Fase 4 — Guías · hecho

Cada guía es un procedimiento numerado que termina en una verificación
ejecutable (`scripts/matrix.sh`, `:checkhealth dohwa`, `:Dohwa keys`).

- `adding-a-module.md` — ya escrita y buena (254 líneas). Se mueve a `guides/`
  y se actualiza el enlace del README raíz.
- `removing-a-module.md` — la mitad que falta: borrar el archivo frente a
  `:Dohwa disable`, qué hace la cascada de `requires`, qué features se quedan en
  su native floor, `lazy-lock.json` y `:Lazy clean`, y el orden correcto (apagar,
  correr la matriz, después borrar).
- `adding-a-plugin.md` — añadir un plugin a un módulo existente: cuándo va como
  `dependencies` de un spec y cuándo merece módulo propio, `dohwa_main`, y el
  conflicto `config()` frente a `setup()` que el kernel reporta en
  `lua/dohwa/init.lua:206`.
- `adding-a-feature.md` — elegir el kind, escribir el native floor, prioridades
  (0 nativo, 50 plugin), por qué el provider es un thunk y qué pasa si lanza.
- `changing-keys.md` — mover una key propia, reservar un namespace, pedir letra
  en `<leader>t` / `]`-`[` / `a`-`i`, declarar un `external`, y leer los tres
  tipos de rechazo (duplicate, prefix shadow, namespace violation).
- `adding-a-language.md` — el recorrido completo de un lenguaje: servidor en
  `editor.lsp`, formatter en `editor.format`, parser en `editor.syntax`, y
  mason frente a binario del sistema.
- `profiles-and-disabling.md` — `default`/`minimal`, el archivo de estado que
  escribe `:Dohwa disable`, `DOHWA_PROFILE`/`DOHWA_LOADER`/`DOHWA_DISABLE`, los
  módulos protegidos y el `--force`.

### Fase 5 — Solución de problemas y rendimiento · hecho

`troubleshooting.md` por síntoma, no por componente: una key no responde, una
key tarda medio segundo (prefix shadow), un plugin no carga nunca, el LSP no se
engancha al buffer ya abierto, `checkhealth` dice *orphan feature*, arranque
lento, el editor se comporta distinto como root (`init.lua:9` fuerza el null
loader). Cada entrada: qué mirar, con qué comando, y qué esperar ver.

`performance.md` recoge el apartado de rendimiento del README, que es el más
valioso y el que menos pinta tiene de README: mediciones, coste por módulo, y
las cinco decisiones tomadas por medición (no añadir `vim.loader.enable()`,
mason en `VeryLazy`, Telescope sin evento, etc.). El README se queda con la
tabla resumen y un enlace.

### Fase 6 — Generador · hecho

[`lua/dohwa/gendoc.lua`](../lua/dohwa/gendoc.lua) emite markdown desde el
broker, el registry y el graph, y escribe
`docs/reference/{keys,features,dependencies,modules}.md`. Expone cuatro
funciones, y las tres últimas son las que impiden que la documentación mienta:

| Función | Comprueba |
|---|---|
| `write(dir)` | escribe las cuatro páginas |
| `check()` | si lo que hay en disco coincide con lo que generaría ahora |
| `broken_links()` | cada `[texto](destino)` relativo de `docs/`, ignorando bloques de código y spans inline |
| `missing_sections()` | que cada módulo activo tenga una sección titulada con su nombre exacto |

Las cuatro superficies que las usan:

- `scripts/gendoc.sh` y `scripts/gendoc.sh --check`, que sale con 1 si hay
  problemas.
- `:Dohwa gendoc` y `:Dohwa gendoc --check`, con completado.
- Una sección `docs` en `:checkhealth dohwa` con los tres informes.
- `scripts/matrix.sh`, que corre `--check` como último paso con nada
  deshabilitado.

Cada página generada empieza con un aviso de "generado por `scripts/gendoc.sh`,
no editar". **Sin fecha de generación, a propósito:** un timestamp haría que
`--check` reportara deriva en cada ejecución y convertiría la única señal
automática de desactualización en ruido.

## Verificación

Las cinco condiciones del plan, y cómo quedaron:

| Condición | Comprobación | Estado |
|---|---|---|
| la matriz sigue en verde con los dos loaders | `scripts/matrix.sh lazy` / `null` | 0 fallos, 18 pasos cada una |
| checkhealth no reporta nada de docs | sección `docs` de `:checkhealth dohwa` | las tres en OK |
| cada módulo activo tiene su sección y `<leader>hm` aterriza | `missing_sections()` | 15/15, verificado también a mano sobre los 31 archivos de `lua/` |
| ningún enlace relativo roto | `broken_links()` | 116 enlaces, 0 rotos |
| el README raíz resume y enlaza, no repite | a ojo | el apartado de rendimiento vive en `performance.md` y el README enlaza |

Nada de esto hay que acordarse de mirar: `scripts/matrix.sh` lo corre entero.
