# Perfiles y apagar cosas

Qué está encendido se decide en cuatro capas, y conocer la precedencia ahorra
mucho tiempo depurando por qué un módulo no arranca.

## La precedencia, de más fuerte a más débil

```
1. DOHWA_DISABLE=a,b          un arranque, sin tocar ningún archivo
2. estado JSON                lo que escribió :Dohwa disable
3. lua/profiles/<nombre>.lua  la configuración que versionas
4. spec.default               qué pasa con un módulo que no está listado
```

Está implementado en `Profile:is_enabled()`
([`lua/dohwa/profile.lua:61`](../../lua/dohwa/profile.lua)) y se lee de arriba
abajo: la primera capa que opine, gana.

Hay además dos cosas que se saltan todo esto:

- **`DOHWA_LOADER=null`** no apaga ningún módulo: los deja todos activos pero sin
  plugins, así que corren solo sus `native`. Es distinto de apagarlos.
- **Correr como root** fuerza `DOHWA_LOADER=null` desde `init.lua:9`, así que un
  `sudo nvim` nunca ejecuta código de plugins.

## Los perfiles

Un perfil es un archivo en `lua/profiles/`:

```lua
-- lua/profiles/default.lua
return {
  default = true,     -- un módulo no listado está ENCENDIDO
  loader = "lazy",
  modules = {},       -- nada que decir: todo entra
}
```

```lua
-- lua/profiles/minimal.lua
return {
  default = false,    -- un módulo no listado está APAGADO
  loader = "lazy",
  modules = {
    ["core.options"] = true,
    ["core.keys"] = true,
    ["core.autocmds"] = true,
    ["core.toggles"] = true,
    ["ui.theme"] = true,
  },
}
```

`default = true` es lo que hace que **dejar un archivo nuevo en `lua/modules/`
funcione sin tocar nada más**. `minimal` invierte el criterio y lista lo que
quiere: el core protegido más un tema, para ver qué es el editor cuando casi todo
está apagado.

Elegir uno:

```bash
DOHWA_PROFILE=minimal nvim
```

### Hacer uno nuevo

```lua
-- lua/profiles/writing.lua
return {
  default = false,
  loader = "lazy",
  modules = {
    ["core.options"] = true,
    ["core.keys"] = true,
    ["core.autocmds"] = true,
    ["core.toggles"] = true,
    ["ui.theme"] = true,
    ["ui.statusline"] = true,
    ["editor.syntax"] = true,
    ["tools.docs"] = true,      -- render de markdown
  },
}
```

Nada que registrar: `Profile:_load_spec()` hace `require("profiles." .. nombre)`.
Un perfil que no existe no impide arrancar — se registra el error y se usa el
spec por defecto.

Un perfil tiene además su **propio archivo de estado**, así que lo que apagues
dentro de `writing` no afecta a `default`.

## El archivo de estado

`:Dohwa disable` no edita Lua: escribe JSON en
`stdpath("state")/dohwa/<perfil>.json`. Por eso la decisión sobrevive al
reinicio sin ensuciar el repositorio.

```bash
# dónde está, exactamente
nvim --headless '+lua io.write(require("dohwa").profile:state_path())' +qa
```

```json
{"tools.git":false,"ui.hints":false}
```

Se puede editar a mano o borrar: borrarlo devuelve todo a lo que diga el perfil.

| Comando | Efecto |
|---|---|
| `:Dohwa disable tools.git` | escribe `false`, revoca features y keys, dice qué dependía |
| `:Dohwa enable tools.git` | escribe `true`; hace falta reiniciar para cargar sus plugins |
| `:Dohwa disable core.keys --force` | los módulos de `core/` son protected y lo exigen |

Apagar en caliente **no descarga** los plugins ya cargados — el mensaje lo dice.
Lo que sí ocurre inmediatamente es que sus features vuelven al native floor y
sus keys se sueltan, con re-arbitraje.

## Las variables de entorno

| Variable | Para qué | Ejemplo |
|---|---|---|
| `DOHWA_PROFILE` | qué perfil usar | `DOHWA_PROFILE=minimal nvim` |
| `DOHWA_LOADER` | `lazy` o `null` | `DOHWA_LOADER=null nvim` |
| `DOHWA_DISABLE` | apagar módulos para un solo arranque | `DOHWA_DISABLE=tools.git,ui.hints nvim` |

`DOHWA_DISABLE` es la que usa `scripts/matrix.sh`, y es por eso que la matriz
puede probar 17 combinaciones sin escribir nada en disco.

Para dejarlas fijas en un alias:

```bash
alias nvim-min='DOHWA_PROFILE=minimal nvim'
alias nvim-bare='DOHWA_LOADER=null nvim'
```

## Los módulos protegidos

Todo lo que está bajo `lua/modules/core/` se construye como `CoreModule`, que
lleva `protected = true`. Dos consecuencias:

1. `:Dohwa disable` los rechaza sin `--force`.
2. **Son los únicos que pueden mapear fuera de una reserva** — el privilegio se
   concede en el paso 3 del boot y es lo que les permite ser dueños de las keys
   globales.

Apagar uno es legítimo pero tiene efectos que no se ven desde su archivo:
sin `core.toggles` **ningún** toggle de ningún módulo se aplica, porque nadie
reservó el prefijo `<leader>t`.

## Diagnosticar por qué algo no está

```
:Dohwa status            el estado de los 15 módulos, con su marca
:Dohwa why tools.finder  estado, razón, dependencias, quién lo necesita
:Dohwa log               lo que pasó en el arranque
:checkhealth dohwa       todo lo anterior, con sugerencias
```

Las marcas de `:Dohwa status`:

| Marca | Estado | Significa |
|---|---|---|
| `+` | `active` | corriendo |
| `-` | `disabled` | el perfil, el estado o `DOHWA_DISABLE` lo apagaron |
| `~` | `skipped` | le falta una dependencia dura; sus features están en el nativo |
| `!` | `error` | un hook lanzó, o el archivo no carga |

Si un módulo sale como `disabled` y no sabes por qué, el orden de sospecha es el
de la precedencia: primero el entorno, después el archivo de estado, después el
perfil.

## Para seguir

- [removing-a-module.md](removing-a-module.md) — apagar frente a borrar.
- [../kernel.md](../kernel.md#profile) — la mecánica de las cuatro capas.
- [../troubleshooting.md](../troubleshooting.md) — "esto no se ha cargado".
