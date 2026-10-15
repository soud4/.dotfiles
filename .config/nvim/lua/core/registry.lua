--- Qué plugins están habilitados.
---
--- Esta lista es la autoridad: `init.lua` la pasa como `spec`, y lazy.nvim
--- importa exactamente estas entradas. Comentar una línea apaga el plugin de
--- verdad (desaparece de `:Lazy`, no solo deja de cargarse).
---
--- Por qué una lista explícita y no `{ import = "plugins" }`: ese import barre
--- el directorio *y además* importa `plugins/init.lua` si existe
--- (`lazy/core/util.lua`, M.lsmod). Con el barrido activo, un registro no
--- gatearía nada — cada spec se importaría dos veces y un plugin comentado
--- seguiría cargando. Son excluyentes, así que acá no hay barrido.
---
--- El costo: agregar un plugin son dos ediciones, su archivo y esta línea. Un
--- archivo en lua/plugins/ que no esté acá no carga y no avisa; de eso se
--- encarga `:checkhealth keyaudit`, que compara esta lista con el directorio.
return {
  -- Apariencia
  { import = "plugins.gruvbox" },
  { import = "plugins.lualine" },
  { import = "plugins.which_key" },
  { import = "plugins.render_markdown" },

  -- Búsqueda
  { import = "plugins.telescope" },

  -- Edición
  { import = "plugins.treesitter" },
  { import = "plugins.cmp" },
  { import = "plugins.autopairs" },
  { import = "plugins.conform" },
  { import = "plugins.gitsigns" },

  -- LSP
  { import = "plugins.lspconfig" },
  { import = "plugins.mason" },
  { import = "plugins.mason_lspconfig" },
}
