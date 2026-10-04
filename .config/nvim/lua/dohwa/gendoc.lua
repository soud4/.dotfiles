--- Generated documentation.
---
--- Everything under `docs/reference/` is written from the live configuration:
--- the key model from the broker, the feature arbitration from the registry,
--- the load order from the graph. Those three things already exist as data, and
--- writing them by hand is the one part of the documentation guaranteed to go
--- stale.
---
--- There is deliberately no timestamp in the output. A generation date would
--- make `--check` report drift on every run, which would turn the only
--- automatic staleness signal into noise.
local M = {}

local HEADER = "<!-- Generado por scripts/gendoc.sh · no editar a mano -->"

local function out_dir()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "docs", "reference")
end

--- Escape the pipe in a markdown table cell. Key sequences contain `|`.
local function cell(text)
  return (tostring(text or ""):gsub("|", "\\|"))
end

--- A key sequence as inline code, which also keeps `<leader>` from being read
--- as an HTML tag.
local function key(lhs)
  return ("`%s`"):format(cell(lhs))
end

-- Pages ---------------------------------------------------------------------

local pages = {}

function pages.keys(dohwa)
  local lines = {
    HEADER,
    "",
    "# Referencia: keys",
    "",
    ("%d mappings aplicados en %d namespaces, tal como los dejó "):format(
      #dohwa.keys.applied, #dohwa.keys:groups()
    ) .. "`KeyBroker:commit()`.",
    "",
    "Un mapping marcado `(plugin)` es una `external` claim: lo instala el plugin,",
    "no el broker, pero entra igual en la detección de colisiones.",
    "",
    "Las reglas que gobiernan esta tabla están en",
    "[../architecture.md](../architecture.md) y los procedimientos en",
    "[../guides/changing-keys.md](../guides/changing-keys.md).",
    "",
    "## Namespaces reservados",
    "",
    "| Prefijo | Para | Dueño | Modos |",
    "|---|---|---|---|",
  }
  for _, group in ipairs(dohwa.keys:groups()) do
    lines[#lines + 1] = ("| %s | %s | `%s` | %s |"):format(
      key(group.prefix),
      cell(group.desc),
      group.owner,
      group.modes and table.concat(group.modes, ", ") or "todos"
    )
  end

  -- Group the mappings by owning module, which is how they are read.
  local by_owner = {}
  for _, map in ipairs(dohwa.keys:list()) do
    by_owner[map.owner] = by_owner[map.owner] or {}
    table.insert(by_owner[map.owner], map)
  end
  local owners = vim.tbl_keys(by_owner)
  table.sort(owners)

  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Mappings por módulo"
  for _, owner in ipairs(owners) do
    lines[#lines + 1] = ""
    lines[#lines + 1] = ("### %s"):format(owner)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "| Modo | Key | Hace |"
    lines[#lines + 1] = "|---|---|---|"
    for _, map in ipairs(by_owner[owner]) do
      lines[#lines + 1] = ("| `%s` | %s | %s |"):format(map.mode, key(map.lhs), cell(map.desc))
    end
  end
  return lines
end

function pages.features(dohwa)
  local lines = {
    HEADER,
    "",
    "# Referencia: features",
    "",
    ("%d features. La columna *gana* es quién manda ahora mismo y con qué "):format(
      #dohwa.registry:names()
    ) .. "prioridad; *pierden* son las implementaciones que quedaron debajo.",
    "",
    "`0` es siempre el native floor. Un feature `optional` puede no resolver a",
    "nada: significa que Neovim no tiene equivalente nativo. Ver",
    "[../guides/adding-a-feature.md](../guides/adding-a-feature.md).",
    "",
    "| Feature | Kind | Declara | Gana | Pierden |",
    "|---|---|---|---|---|",
  }
  local optional = {}
  for _, name in ipairs(dohwa.registry:names()) do
    local feature = dohwa.registry:get(name)
    local winner = feature:winner()
    local losers = {}
    for _, impl in ipairs(feature:losers()) do
      losers[#losers + 1] = ("`%s:%d`"):format(impl.owner, impl.priority)
    end
    lines[#lines + 1] = ("| `%s` | %s | `%s` | %s | %s |"):format(
      name,
      feature.kind,
      feature.owner,
      winner and ("`%s:%d`"):format(winner.owner, winner.priority) or "—",
      #losers > 0 and table.concat(losers, " ") or "—"
    )
    if feature.optional then
      optional[#optional + 1] = name
    end
  end
  if #optional > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Sin native floor (`optional`)"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Estos no tienen implementación nativa porque Neovim no hace nada"
    lines[#lines + 1] = "equivalente. Con su módulo apagado resuelven a nada, en silencio."
    lines[#lines + 1] = ""
    for _, name in ipairs(optional) do
      lines[#lines + 1] = ("- `%s` — %s"):format(name, cell(dohwa.registry:get(name).desc))
    end
  end
  local undeclared = dohwa.registry:undeclared()
  if #undeclared > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Implementados sin declarar"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "Placeholders: o el módulo que los declara está apagado, o el nombre"
    lines[#lines + 1] = "tiene una errata. Ver [../troubleshooting.md](../troubleshooting.md)."
    lines[#lines + 1] = ""
    for _, name in ipairs(undeclared) do
      lines[#lines + 1] = ("- `%s`"):format(name)
    end
  end
  return lines
end

function pages.dependencies(dohwa)
  local lines = {
    HEADER,
    "",
    "# Referencia: dependencias",
    "",
    "El orden de carga que resolvió `Graph:resolve()`. `requires` es dura —si",
    "falta, el dependiente se salta, en cascada— y `optional` solo ordena las",
    "declaraciones. Ver [../kernel.md](../kernel.md#graph).",
    "",
    "## Orden de carga",
    "",
    "| # | Módulo | requires | optional | Lo necesitan |",
    "|---|---|---|---|---|",
  }
  for i, name in ipairs(dohwa.order) do
    local module = dohwa.modules[name]
    local dependents = dohwa.graph:dependents(name)
    local function list(items)
      if #items == 0 then
        return "—"
      end
      return "`" .. table.concat(items, "` `") .. "`"
    end
    lines[#lines + 1] = ("| %d | `%s` | %s | %s | %s |"):format(
      i, name, list(module.requires), list(module.optional), list(dependents)
    )
  end

  if next(dohwa.skipped) then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Saltados"
    lines[#lines + 1] = ""
    local names = vim.tbl_keys(dohwa.skipped)
    table.sort(names)
    for _, name in ipairs(names) do
      lines[#lines + 1] = ("- `%s` — %s"):format(name, cell(dohwa.skipped[name]))
    end
  end
  if #dohwa.cycle > 0 then
    lines[#lines + 1] = ""
    lines[#lines + 1] = "## Ciclo"
    lines[#lines + 1] = ""
    lines[#lines + 1] = "`" .. table.concat(dohwa.cycle, "` -> `") .. "`"
  end
  return lines
end

function pages.modules(dohwa)
  local lines = {
    HEADER,
    "",
    "# Referencia: módulos",
    "",
    ("%d módulos descubiertos en `lua/modules/`. Cada uno se documenta en la "):format(
      #dohwa:names()
    ) .. "página de su grupo:",
    "[../modules/core.md](../modules/core.md) ·",
    "[../modules/editor.md](../modules/editor.md) ·",
    "[../modules/tools.md](../modules/tools.md) ·",
    "[../modules/ui.md](../modules/ui.md).",
    "",
    "| Módulo | Estado | Protegido | Hooks | Plugins |",
    "|---|---|---|---|---|",
  }
  for _, name in ipairs(dohwa:names()) do
    local module = dohwa.modules[name]
    local hooks = {}
    for _, hook in ipairs({ "native", "declare", "plugins", "setup" }) do
      if type(module[hook]) == "function" then
        hooks[#hooks + 1] = hook
      end
    end
    local specs = {}
    if module:has_plugins() then
      local ok, list = pcall(module.plugins, dohwa:context(module))
      if ok and type(list) == "table" then
        for _, spec in ipairs(list) do
          if type(spec[1]) == "string" then
            specs[#specs + 1] = spec[1]
          end
          for _, dep in ipairs(spec.dependencies or {}) do
            local id = type(dep) == "table" and dep[1] or dep
            if type(id) == "string" then
              specs[#specs + 1] = id
            end
          end
        end
      end
    end
    lines[#lines + 1] = ("| `%s` | %s | %s | %s | %s |"):format(
      name,
      module.state,
      module.protected and "sí" or "no",
      table.concat(hooks, " "),
      #specs > 0 and table.concat(specs, "<br>") or "—"
    )
  end

  lines[#lines + 1] = ""
  lines[#lines + 1] = "## Descripciones"
  lines[#lines + 1] = ""
  for _, name in ipairs(dohwa:names()) do
    lines[#lines + 1] = ("- `%s` — %s"):format(name, cell(dohwa.modules[name].description))
  end
  lines[#lines + 1] = ""
  lines[#lines + 1] = ("Loader: `%s` · profile: `%s`."):format(dohwa.loader:id(), dohwa.profile.name)
  return lines
end

local ORDER = { "keys", "features", "dependencies", "modules" }

-- Writing -------------------------------------------------------------------

local function render(dohwa, name)
  return table.concat(pages[name](dohwa), "\n") .. "\n"
end

local function read(path)
  local fd = io.open(path, "r")
  if not fd then
    return nil
  end
  local body = fd:read("*a")
  fd:close()
  return body
end

--- Write every reference page. Returns the paths written and any that failed.
---@param dir string|nil target directory, for --check
---@return string[] written, string[] failed
function M.write(dir)
  local dohwa = require("dohwa")
  dir = dir or out_dir()
  vim.fn.mkdir(dir, "p")
  local written, failed = {}, {}
  for _, name in ipairs(ORDER) do
    local path = vim.fs.joinpath(dir, name .. ".md")
    local ok, body = pcall(render, dohwa, name)
    local fd = ok and io.open(path, "w") or nil
    if fd then
      fd:write(body)
      fd:close()
      written[#written + 1] = path
    else
      failed[#failed + 1] = ("%s: %s"):format(path, ok and "could not be written" or tostring(body))
    end
  end
  return written, failed
end

--- Compare what is on disk against what this configuration would generate now.
---@return string[] stale page names
function M.check()
  local dohwa = require("dohwa")
  local stale = {}
  for _, name in ipairs(ORDER) do
    local ok, body = pcall(render, dohwa, name)
    if not ok then
      stale[#stale + 1] = name .. " (error al generar)"
    elseif read(vim.fs.joinpath(out_dir(), name .. ".md")) ~= body then
      stale[#stale + 1] = name
    end
  end
  return stale
end

--- Relative link targets in the handwritten pages that do not resolve.
---@return string[] broken, integer checked
function M.broken_links()
  local docs = vim.fs.joinpath(vim.fn.stdpath("config"), "docs")
  local broken, checked = {}, 0
  local files = vim.fn.globpath(docs, "**/*.md", false, true)
  table.sort(files)
  for _, file in ipairs(files) do
    local body = read(file) or ""
    local base = vim.fs.dirname(file)
    local lineno, fenced = 0, false
    for line in vim.gsplit(body, "\n") do
      lineno = lineno + 1
      if line:match("^%s*```") then
        fenced = not fenced
      elseif not fenced then
        -- Inline code spans hold link syntax as an example, not as a link.
        for target in line:gsub("`[^`]*`", ""):gmatch("%]%(([^)]+)%)") do
          if not target:match("^%a[%w+.-]*:") and not target:match("^#") then
            checked = checked + 1
            local path = vim.fs.normalize(vim.fs.joinpath(base, (target:gsub("#.*$", ""))))
            if not (vim.uv or vim.loop).fs_stat(path) then
              broken[#broken + 1] = ("%s:%d -> %s"):format(vim.fn.fnamemodify(file, ":."), lineno, target)
            end
          end
        end
      end
    end
  end
  return broken, checked
end

--- Active modules with no section of their own in their group's page, and
--- group pages that do not exist. The heading must carry the module's exact
--- name, because that is what `<leader>hm` searches for.
---@return string[] missing
function M.missing_sections()
  local dohwa = require("dohwa")
  local docs = vim.fs.joinpath(vim.fn.stdpath("config"), "docs")
  local cache, missing = {}, {}
  for _, name in ipairs(dohwa.order) do
    local group, short = name:match("^([^.]+)%.(.+)$")
    if group then
      local path = vim.fs.joinpath(docs, "modules", group .. ".md")
      if cache[path] == nil then
        cache[path] = read(path) or false
      end
      if not cache[path] then
        missing[#missing + 1] = ("%s (falta docs/modules/%s.md)"):format(name, group)
      elseif not cache[path]:match("\n#+%s+[^\n]*%f[%w]" .. vim.pesc(short) .. "%f[%W]") then
        missing[#missing + 1] = ("%s (sin sección en docs/modules/%s.md)"):format(name, group)
      end
    end
  end
  return missing
end

return M
