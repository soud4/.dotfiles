--- `:checkhealth keyaudit`
local M = {}

--- El registro (lua/core/registry.lua) es la autoridad sobre qué plugins
--- carga lazy, así que un archivo en lua/plugins/ que no esté listado no
--- carga y no avisa. Esto convierte ese silencio en un aviso.
local function check_registry()
  vim.health.start("registro de plugins")

  local ok, registry = pcall(require, "core.registry")
  if not ok then
    vim.health.error("no se pudo cargar core.registry: " .. tostring(registry))
    return
  end

  local listed = {}
  for _, spec in ipairs(registry) do
    local name = type(spec) == "table" and spec.import
    if type(name) == "string" then
      listed[name:gsub("^plugins%.", "")] = true
    end
  end

  local dir = vim.fs.joinpath(vim.fn.stdpath("config"), "lua", "plugins")
  local on_disk = {}
  for name, kind in vim.fs.dir(dir) do
    if kind == "file" and name:sub(-4) == ".lua" then
      on_disk[name:sub(1, -5)] = true
    end
  end

  local orphans, missing = {}, {}
  for name in pairs(on_disk) do
    if not listed[name] then
      orphans[#orphans + 1] = name
    end
  end
  for name in pairs(listed) do
    if not on_disk[name] then
      missing[#missing + 1] = name
    end
  end
  table.sort(orphans)
  table.sort(missing)

  for _, name in ipairs(orphans) do
    vim.health.warn(("lua/plugins/%s.lua existe pero no está en el registro, así que no carga")
      :format(name))
  end
  for _, name in ipairs(missing) do
    vim.health.error(("el registro lista plugins.%s pero lua/plugins/%s.lua no existe")
      :format(name, name))
  end

  if #orphans == 0 and #missing == 0 then
    vim.health.ok(("registro y directorio coinciden (%d plugins)"):format(vim.tbl_count(listed)))
  end
end

function M.check()
  check_registry()

  vim.health.start("keymaps")
  local result = require("keyaudit").audit()

  if #result.shadows == 0 then
    vim.health.ok("no prefix shadows")
  else
    for _, s in ipairs(result.shadows) do
      vim.health.warn(("%s: %s is a prefix of %s, so it waits for 'timeoutlen' (%dms)")
        :format(s.mode, s.lhs, s.shadowed_by, vim.o.timeoutlen))
    end
  end

  if #result.duplicates == 0 then
    vim.health.ok("no duplicate mappings")
  else
    for _, d in ipairs(result.duplicates) do
      vim.health.info(("%s: %s is mapped more than once"):format(d.mode, d.lhs))
    end
  end
end

return M
