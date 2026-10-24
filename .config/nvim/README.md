# Configuración de Neovim

lazy.nvim, un archivo por plugin, sin capas propias.

## Requisitos

- Neovim 0.12+
- `tree-sitter-cli` (vía Mason): la rama `main` de nvim-treesitter compila los parsers con ella
- Node portable en `~/.local/opt/node`, que `init.lua` agrega al PATH solo dentro de Neovim
- `rg`, `make` y un compilador de C (fzf-native y los parsers)

## Estructura

```
init.lua            leaders, PATH (node + mason/bin), lazy.nvim
lua/config/         options, keymaps, autocmds
lua/plugins/        un archivo por plugin; lazy los importa todos
  lsp.lua           nvim-lspconfig + overrides por servidor + mason
```

Para agregar un plugin, crea `lua/plugins/<nombre>.lua`. Para agregar un servidor, añádelo
a la tabla `servers` de `lsp.lua` e instálalo con Mason.

## Máquina nueva

```
:MasonInstall intelephense typescript-language-server vue-language-server tailwindcss-language-server html-lsp css-lsp emmet-language-server clangd lua-language-server bash-language-server pyright prettierd tree-sitter-cli
```

Mason solo carga cuando usas sus comandos. Los binarios se encuentran porque `init.lua` pone `mason/bin` en el PATH.

## Mantenimiento

```
:Lazy                   plugins (lazy-lock.json fija versiones)
:Mason                  servidores y formateadores
:TSUpdate               parsers de tree-sitter
:checkhealth which-key  keymaps que se solapan
:checkhealth vim.lsp    clientes LSP
```
