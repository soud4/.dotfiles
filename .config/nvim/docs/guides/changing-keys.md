# Cambiar keys

Todo mapping de esta configuración pasa por el KeyBroker, que valida el modelo
completo antes de aplicar nada. Esta guía es el recorrido de las cinco cosas que
se quieren hacer con una key, más cómo leer los tres rechazos.

Antes de tocar nada, mira el estado actual:

```
:Dohwa keys              todos los namespaces y todos los mappings con su dueño
:Dohwa keys <leader>f    solo bajo un prefijo
<leader>??               lo mismo, interactivo
```

## 1. Mover una key que ya es tuya

Si el módulo es dueño del prefijo, es una línea:

```lua
-- lua/modules/tools/finder.lua
ctx:slot("n", "<leader>ff", "finder.files")   -- antes
ctx:slot("n", "<leader>fp", "finder.files")   -- después
```

Reinicia y comprueba con `:Dohwa keys <leader>f`. No hace falta nada más: el
broker borra las keys aplicadas antes de volver a aplicar.

## 2. Mover una key global

Las keys globales (`gd`, `K`, `]d`, `<Tab>`) pertenecen a `core.keys`, y están
atadas a un **feature**, no a una implementación. Cambiar `gd` para toda la
configuración —con Telescope, con el LSP nativo o con lo que gane mañana— es una
línea en un solo archivo:

```lua
-- lua/modules/core/keys.lua
ctx:slot("n", "gd", "goto.definition")     -- antes
ctx:slot("n", "<leader>gd", "goto.definition")   -- ojo: <leader>g es de tools.git
```

Dos cuidados:

- **El prefijo tiene que estar libre o ser de core.** `core.keys` es protected y
  puede mapear en el namespace global, pero no dentro de la reserva de otro
  módulo: `<leader>gd` sería una `namespace violation` contra `tools.git`.
- **Cuidado con los prefix shadows.** Mapear `g` a secas haría esperar
  `timeoutlen` a `gd`, `gD`, `gr`, `gi`, `gt`, `gO`. El broker lo reporta, no lo
  impide.

## 3. Reservar un namespace nuevo

```lua
native = function(ctx)
  ctx:reserve("<leader>e", "Explorer")
  ctx:slot("n", "<leader>ee", "explorer.open")
end
```

Prefijos de un nivel ya tomados ahora mismo:

| Libres bajo `<leader>` | Tomados |
|---|---|
| `a` `b` `e` `i` `j` `k` `l` `m` `n` `o` `p` `q` `r` `u` `v` `x` `y` `z` | `=` `?` `F` `c` `d` `f` `g` `h` `s` `t` `/` |

Dos reglas:

- **No mapees el prefijo a sí mismo.** `ui.hints` reserva `<leader>?` y mapea
  `<leader>??`, con dos interrogaciones, justo por esto: `<leader>?` mapeado
  sería un prefix shadow contra todos sus hijos.
- **Puedes estrechar por modo.** `ctx:reserve("-", "Explorer", { modes = { "n" } })`
  deja `-` libre en los demás modos. Dos reservas del mismo prefijo solo chocan
  si sus modos se solapan, que es por lo que `editor.pairs` puede ser dueño de
  `[` en insert mientras `core.keys` lo es en normal.

## 4. Pedir una letra en un namespace compartido

Tres namespaces no pertenecen a quien los usa, sino que reparten letras:

```lua
-- <leader>t — toggles
ctx:toggle("m", "Toggle: markdown rendering", function() ... end)

-- ] / [ — saltos (modos n, x, o)
ctx:jump("h", "hunk", {
  next = function() ctx:call("git.hunk_next") end,
  prev = function() ctx:call("git.hunk_prev") end,
})

-- a / i — text objects (modos o, x)
ctx:textobject("h", "hunk", { inner = function() ctx:call("git.select_hunk") end })
```

La letra es exclusiva y el segundo que la pida es rechazado nombrando a los dos
módulos. Letras ocupadas hoy:

| Namespace | Letras tomadas |
|---|---|
| `<leader>t` | `w` `d` `n` `s` (core) · `b` (git) · `f` (format) · `h` (lsp) · `m` (docs) |
| `]` / `[` | `d` (diagnósticos) · `h` (hunks) · `f` `C` `a` (tree-sitter) · `c` libre a propósito, es la motion de diff |
| `a` / `i` | `f` `c` `a` `i` `l` (tree-sitter) · `h` (hunks) |

Si solo quieres que la letra sea **visible** porque el plugin instala el mapping
él mismo, añade `external = true`:

```lua
ctx:textobject("f", "function", { external = true })
```

## 5. Declarar un mapping que instala el plugin

```lua
declare = function(ctx)
  ctx:external("i", "<CR>", "Confirm completion")
end
```

No se aplica —lo hace el plugin— pero entra en la detección de colisiones y sale
en `:Dohwa keys` marcado como `(plugin)`. Sin esto, el mapping es invisible para
el arbitraje, que es el agujero que tenían nvim-treesitter-textobjects y
gitsigns antes de declararse así.

Y el caso raro: un módulo que quiere **retractarse** de sus propias keys porque
el plugin las va a instalar. `ctx:revoke_keys()` suelta todo lo que ese módulo
declaró hasta ese momento, sin aplicar nada — el broker commitea una sola vez,
después de que todos hayan hablado. `editor.pairs` lo hace con los once
caracteres de pares.

## Los tres rechazos, y qué significan

Todos salen en `:checkhealth dohwa`, sección `keys`.

### namespace violation

```
tools.explorer: n <leader>ge — namespace violation
  '<leader>g' is reserved by tools.git
```

Estás mapeando dentro de la reserva de otro, o en el namespace global sin ser un
módulo protected. El mensaje alternativo es
`global namespace: reserve a prefix or use a core slot`, y ese es literalmente el
arreglo: reserva un prefijo propio, o si la key debe ser global, declara el
feature y deja que `core.keys` le dé el slot.

### duplicate mapping

```
tools.explorer: n <leader>ee — duplicate mapping
  held by tools.other
```

Dos módulos en la misma secuencia. **Gana la prioridad más alta** (50 por
defecto, empate → nombre de dueño menor) y el perdedor no se aplica. Arreglo:
mueve uno de los dos, o pásale `priority` explícita si de verdad quieres que uno
gane:

```lua
ctx:map("n", "<leader>ee", fn, { desc = "...", priority = 80 })
```

### prefix shadow

```
n <leader>f (tools.finder) delays <leader>fb, <leader>fc, <leader>ff
  it only fires after 'timeoutlen' (400ms)
```

**No es un error y las dos keys se aplican.** Es un aviso de latencia: la corta
no dispara hasta que expiran los 400 ms. Si lo ves, casi siempre quieres mover la
corta a una secuencia de dos caracteres (`<leader>ff`) o quitarla.

Este caso concreto fue real en esta configuración, y es la razón de que el
KeyTrie exista. Otro ejemplo que ya está arreglado: Neovim 0.11 trae `grn`,
`gra`, `grr`, `gri`, `grt` de serie, y como aquí se mapea `gr`, `core.keys` los
borra explícitamente para que `gr` sea instantáneo.

## Dónde **no** poner un mapping

- **`vim.keymap.set` directo para algo global.** El broker no lo ve, así que no
  detecta la colisión y no sale en el listado. Las únicas excepciones legítimas
  son los mappings **locales de buffer** que instala un módulo desde un
  autocommand: la `q` de las ventanas auxiliares en `core.autocmds`, las keys
  del viewer en `tools.docs`.
- **`keys = { ... }` en el spec de lazy.nvim.** Esquiva el arbitraje por
  completo. Si quieres carga diferida por key, no hace falta: el broker es dueño
  del mapping y lazy.nvim engancha `require`, así que un `lazy = true` sin
  trigger ya carga el plugin en la primera pulsación real.
- **`init.lua`.** Solo los leaders, y tienen que estar ahí porque todo lo demás
  mapea contra ellos.

## Verificar

```bash
nvim --headless "+checkhealth dohwa" +qa    # 0 rejected, 0 shadowed
scripts/matrix.sh lazy                      # ningún rechazo al apagar módulos
```

Y a mano: `:Dohwa keys <tu prefijo>` para ver que la key está aplicada y con el
dueño correcto, y pulsarla, que sigue siendo la prueba definitiva.

## Para seguir

- [../modules/core.md](../modules/core.md#keys) — el módulo dueño de las keys
  globales.
- [../kernel.md](../kernel.md#keybroker) — las tres pasadas de `commit()`.
- [../glossary.md](../glossary.md) — slot, reservation, external claim.
