# Documentación de Dohwa

El mapa de la configuración. Cada página responde a una pregunta concreta; si
no sabes por dónde empezar, [architecture.md](architecture.md) explica las tres
reglas sobre las que se sostiene todo lo demás.

Se lee dentro de Neovim: `<leader>hh` abre el selector de páginas, `<leader>hi`
vuelve a este índice, `<leader>hm` salta a la documentación del archivo que
estás editando y `<CR>` sigue los enlaces de una página a otra. `:Docs <tab>`
hace lo mismo desde la línea de comandos.

## Entender

| Página | Responde a |
|---|---|
| [architecture.md](architecture.md) | ¿Por qué está construido así? Las tres reglas, el object model, el boot paso a paso. |
| [kernel.md](kernel.md) | ¿Qué hace cada archivo de `lua/dohwa/`? Una sección por pieza del kernel. |
| [glossary.md](glossary.md) | ¿Qué es un *feature*, un *slot*, un *thunk*, el *native floor*? |

## Los módulos

Una página por grupo, con una ficha por módulo: propósito, native floor,
features que declara e implementa, keys, plugins, coste y qué se pierde al
apagarlo.

| Página | Módulos |
|---|---|
| [modules/core.md](modules/core.md) | `options` · `keys` · `autocmds` · `toggles` |
| [modules/editor.md](modules/editor.md) | `lsp` · `complete` · `format` · `pairs` · `syntax` |
| [modules/tools.md](modules/tools.md) | `finder` · `git` · `docs` |
| [modules/ui.md](modules/ui.md) | `theme` · `statusline` · `hints` |

## Hacer cambios

| Guía | Para |
|---|---|
| [guides/adding-a-module.md](guides/adding-a-module.md) | Añadir un plugin o una unidad nueva. |
| [guides/removing-a-module.md](guides/removing-a-module.md) | Quitar uno, y qué revisar antes. |
| [guides/adding-a-plugin.md](guides/adding-a-plugin.md) | Añadir un plugin a un módulo que ya existe. |
| [guides/adding-a-feature.md](guides/adding-a-feature.md) | Crear una capacidad nueva con su native floor. |
| [guides/changing-keys.md](guides/changing-keys.md) | Mover una key, reservar un namespace, resolver una colisión. |
| [guides/adding-a-language.md](guides/adding-a-language.md) | Servidor LSP, formatter y parser para un lenguaje nuevo. |
| [guides/profiles-and-disabling.md](guides/profiles-and-disabling.md) | Perfiles, `:Dohwa disable`, variables de entorno. |

## Referencia

Las cuatro primeras las escribe `scripts/gendoc.sh` leyendo la configuración en
ejecución: no se editan a mano y no pueden quedar desactualizadas.

| Página | Contenido |
|---|---|
| [reference/keys.md](reference/keys.md) | Todas las keys aplicadas, con su dueño y su namespace. |
| [reference/features.md](reference/features.md) | Cada feature, quién gana y quién pierde. |
| [reference/dependencies.md](reference/dependencies.md) | Orden de carga y árbol de dependencias. |
| [reference/modules.md](reference/modules.md) | Estado, plugins y coste de cada módulo. |
| [troubleshooting.md](troubleshooting.md) | Síntomas concretos y dónde mirar. |
| [performance.md](performance.md) | Mediciones y las decisiones que se tomaron por ellas. |

## Estado

Qué está escrito y qué falta. [plan.md](plan.md) tiene el plan completo, con
las fases, las convenciones de escritura y el contrato de los anchors.

| Fase | Entrega | Estado |
|---|---|---|
| 0 | Lector de documentación en Neovim (`tools.docs`, `<leader>h`) | hecho |
| 1 | Este índice, el plan y las convenciones | hecho |
| 2 | `architecture.md` · `kernel.md` · `glossary.md` | hecho |
| 3 | `modules/{core,editor,tools,ui}.md` | hecho |
| 4 | `guides/*` — siete guías | hecho |
| 5 | `troubleshooting.md` · `performance.md` | hecho |
| 6 | Generador `scripts/gendoc.sh` y `reference/*` | hecho |

Lo que mantiene todo esto honesto:

```bash
scripts/gendoc.sh            regenera docs/reference/*.md
scripts/gendoc.sh --check    deriva, enlaces rotos y módulos sin sección
```

`scripts/matrix.sh` lo corre como último paso, `:checkhealth dohwa` tiene una
sección `docs` con lo mismo, y `:Dohwa gendoc [--check]` lo hace desde dentro
del editor.
