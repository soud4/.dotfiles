<!-- Generado por scripts/gendoc.sh · no editar a mano -->

# Referencia: módulos

15 módulos descubiertos en `lua/modules/`. Cada uno se documenta en la página de su grupo:
[../modules/core.md](../modules/core.md) ·
[../modules/editor.md](../modules/editor.md) ·
[../modules/tools.md](../modules/tools.md) ·
[../modules/ui.md](../modules/ui.md).

| Módulo | Estado | Protegido | Hooks | Plugins |
|---|---|---|---|---|
| `core.autocmds` | active | sí | native | — |
| `core.keys` | active | sí | native | — |
| `core.options` | active | sí | native | — |
| `core.toggles` | active | sí | native | — |
| `editor.complete` | active | no | native declare plugins setup | hrsh7th/nvim-cmp<br>hrsh7th/cmp-nvim-lsp<br>hrsh7th/cmp-buffer<br>hrsh7th/cmp-path<br>L3MON4D3/LuaSnip<br>saadparwaiz1/cmp_luasnip<br>rafamadriz/friendly-snippets |
| `editor.format` | active | no | native declare plugins | stevearc/conform.nvim |
| `editor.lsp` | active | no | native declare plugins setup | neovim/nvim-lspconfig<br>williamboman/mason.nvim<br>williamboman/mason-lspconfig.nvim<br>williamboman/mason.nvim |
| `editor.pairs` | active | no | native declare plugins setup | windwp/nvim-autopairs |
| `editor.syntax` | active | no | native declare plugins setup | nvim-treesitter/nvim-treesitter<br>nvim-treesitter/nvim-treesitter-textobjects |
| `tools.docs` | active | no | native declare plugins setup | MeanderingProgrammer/render-markdown.nvim<br>nvim-tree/nvim-web-devicons |
| `tools.finder` | active | no | native declare plugins setup | nvim-telescope/telescope.nvim<br>nvim-lua/plenary.nvim<br>nvim-telescope/telescope-fzf-native.nvim<br>nvim-tree/nvim-web-devicons |
| `tools.git` | active | no | native declare plugins | lewis6991/gitsigns.nvim |
| `ui.hints` | active | no | native declare plugins | folke/which-key.nvim |
| `ui.statusline` | active | no | native declare plugins | nvim-lualine/lualine.nvim<br>nvim-tree/nvim-web-devicons |
| `ui.theme` | active | no | native declare plugins | ellisonleao/gruvbox.nvim |

## Descripciones

- `core.autocmds` — Core autocommands
- `core.keys` — Global keys and universal features
- `core.options` — Editor options
- `core.toggles` — Toggle namespace
- `editor.complete` — Completion and snippets
- `editor.format` — Formatting
- `editor.lsp` — Language servers
- `editor.pairs` — Automatic pairs
- `editor.syntax` — Syntax, indentation and text objects
- `tools.docs` — Documentation browser
- `tools.finder` — Fuzzy finder
- `tools.git` — Git signs and hunks
- `ui.hints` — Key hints
- `ui.statusline` — Statusline
- `ui.theme` — Colour scheme

Loader: `lazy` · profile: `default`.
