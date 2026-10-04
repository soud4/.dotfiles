# Quitar un módulo

Hay dos operaciones distintas y conviene no confundirlas: **apagar** un módulo
(reversible, persistente, sin tocar archivos) y **borrarlo** (permanente). El
orden correcto es siempre apagar primero, comprobar, y borrar después.

## Apagar

```
:Dohwa disable tools.finder
```

Eso hace cuatro cosas, en este orden
([`lua/dohwa/init.lua:224`](../../lua/dohwa/init.lua)):

1. **Calcula los dependientes** con `graph:dependents(name)` — solo por aristas
   duras — y te los dice en el mensaje.
2. **Escribe la decisión** en `stdpath("state")/dohwa/<profile>.json`, así que
   sobrevive al reinicio sin editar ningún Lua.
3. **Revoca sus features** (`registry:revoke_owner`) y **suelta sus keys**
   (`keys:release`), que vuelve a arbitrar el modelo completo: un prefijo que
   acaba de quedar libre pasa a estar disponible para quien lo quisiera.
4. Marca el módulo como `disabled` con la razón `disabled at runtime`.

Lo que **no** hace: descargar los plugins que ya estén cargados. El mensaje lo
dice (`restart to unload its plugins`), porque descargar un plugin Lua en
caliente no es algo que Neovim pueda hacer de forma fiable.

Para revertir: `:Dohwa enable tools.finder` y reiniciar.

### Variantes

| Qué quieres | Cómo |
|---|---|
| un solo arranque, sin persistir | `DOHWA_DISABLE=tools.finder nvim` |
| varios a la vez | `DOHWA_DISABLE=tools.git,ui.hints nvim` |
| un módulo de `core/` | `:Dohwa disable core.toggles --force` |
| todo lo que no sea core | `DOHWA_PROFILE=minimal nvim` |
| ningún plugin, todo nativo | `DOHWA_LOADER=null nvim` |

## Qué pasa con lo que dependía de él

Aquí está la diferencia entre los dos tipos de arista, y es la razón de que
existan:

- **`requires` (dura).** El dependiente pasa a estado `skipped` y **todos sus
  features caen a su native floor**. La cascada es transitiva: si C requiere B y
  B requiere A, apagar A salta B y C. `:Dohwa status` los marca con `~` y la
  razón dice `requires 'A' (disabled)`.
- **`optional` (blanda).** No pasa nada. El dependiente sigue activo y
  simplemente deja de encontrar lo que buscaba — que es por lo que todo consumo
  de otro módulo se escribe con fallback:
  `ctx:value("lsp.capabilities", <nativo>)`.

En esta configuración **ningún módulo tiene `requires`**: las seis relaciones
que existen son todas `optional`. Eso es deliberado, y significa que apagar
cualquier cosa nunca cascadea hoy. Si añades un `requires`, estás añadiendo la
primera forma de que apagar un módulo apague otro, y la matriz te lo dirá.

Para verlo antes de hacer nada:

```
:Dohwa why tools.finder
```

```
tools.finder — Fuzzy finder
state    : active
requires : —
optional : editor.lsp
needed by: —
protected: false
```

`needed by` lista solo dependientes duros: es la respuesta a "qué se rompe".

## Lo que hay que revisar antes de borrar

Un módulo puede dejar tres rastros en el resto del sistema, y ninguno de los tres
es visible desde su propio archivo:

1. **Features que declara y otros implementan.** `tools.docs` declara
   `docs.browse` y `tools.finder` lo implementa. Si borras `tools.docs`, la
   implementación de `finder` se queda como *implemented but never declared* —
   inofensivo, pero es basura que `:checkhealth dohwa` te va a recordar.
   Búscalo así:

   ```bash
   grep -rn "docs\." lua/modules --include=*.lua | grep -v tools/docs.lua
   ```

2. **Features que otros declaran y él implementa.** `tools.finder` implementa
   seis slots de `core.keys`. Al borrarlo esos features volverán a su nativo
   solos; no hay nada que hacer, pero sí hay algo que comprobar: que el nativo
   sigue siendo usable, no solo que existe.

3. **Letras en namespaces compartidos.** Si borras `tools.git`, las letras `h`
   de `]`/`[` y de `a`/`i` y la `b` de toggles quedan libres. Nada se rompe, pero
   si alguien las quería, ahora las puede pedir.

```
:Dohwa features        # quién gana qué ahora mismo
:Dohwa keys <prefijo>  # qué keys se quedan sin dueño
```

## Borrar

```bash
:Dohwa disable tools.explorer        # primero, y comprueba
scripts/matrix.sh lazy               # ¿sigue todo OK?

rm lua/modules/tools/explorer.lua    # ahora sí
nvim --headless "+Lazy! clean" +qa   # quita los plugins que ya no reclama nadie
```

`Lazy! clean` borra del disco los plugins que ningún spec menciona ya, y
actualiza `lazy-lock.json`. Ese lockfile sí conviene versionarlo: es lo que hace
que otra máquina instale exactamente los mismos commits.

Si el módulo estaba apagado con `:Dohwa disable`, acuérdate de limpiar el
override: el archivo de estado seguirá teniendo `{"tools.explorer": false}` para
un módulo que ya no existe. Es inofensivo (`is_enabled` solo se consulta para
módulos descubiertos), pero es ruido:

```bash
cat "$(nvim --headless '+lua io.write(require("dohwa").profile:state_path())' +qa 2>&1)"
```

## Quitar un plugin sin quitar el módulo

Caso distinto: el módulo se queda, el plugin se va. Borra el spec de `plugins`,
borra el `implement` que lo usaba y borra su `setup` si era el único. El feature
vuelve a su nativo y nada más cambia.

Si eso deja el módulo sin `plugins`, `discover` lo construirá como `Module` en
vez de `PluginModule` en el siguiente arranque, y `declare` seguirá corriendo
(solo se salta para módulos *con* plugins cuando el loader no instala). Así que
no olvides mover lo que haya en `declare` a `native` si tiene que correr siempre.

## Verificar

```bash
nvim --headless "+checkhealth dohwa" +qa
scripts/matrix.sh lazy
scripts/matrix.sh null
```

Lo que tiene que seguir siendo cierto:

- **0 orphan features.** Un feature sin ninguna implementación significa que una
  key no hace nada. Si aparece uno al quitar tu módulo, es que algo dependía de
  él sin declararlo.
- **0 rejected mappings.** Si aparece un rechazo nuevo, dos módulos querían el
  mismo prefijo y el que lo tenía era el que acabas de quitar.
- **Ningún `skipped` inesperado** en `:Dohwa status`.

## Para seguir

- [profiles-and-disabling.md](profiles-and-disabling.md) — perfiles y
  precedencia completa.
- [adding-a-module.md](adding-a-module.md) — la operación inversa.
- [../troubleshooting.md](../troubleshooting.md) — cuando algo de esto sale raro.
