--- Language servers.
---
--- On Neovim 0.12 `vim.lsp.config()` and `vim.lsp.enable()` are native, so
--- nvim-lspconfig is little more than a library of sensible defaults. Which
--- servers get started, with which filetypes and settings, is config/servers.lua.
local lsp = require("config.servers")
local u = require("core.utils")

-- Telescope for anything that produces a list; vim.lsp.buf for the rest. The
-- require is deferred, so a buffer with a server attached does not pull
-- Telescope in until one of these keys is actually used.
local picker = u.defer("telescope.builtin")

--- Which server wins when several of them serve inlay hints for one buffer.
--- Higher goes first; anything unlisted sits in the middle. ts_ls carries the
--- Vue plugin, so it already answers for .vue buffers and vue_ls loses nothing
--- worth keeping.
local hint_priority = {
  ts_ls = 90,
  clangd = 90,
  lua_ls = 90,
  pyright = 90,
  vue_ls = 10,
}

--- The client whose inlay hints this buffer draws, or nil when none serves them.
local function hint_owner(bufnr)
  local best, best_rank
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/inlayHint" })) do
    local rank = hint_priority[client.name] or 50
    if not best_rank or rank > best_rank or (rank == best_rank and client.id < best.id) then
      best, best_rank = client, rank
    end
  end
  return best
end

--- Neovim keeps one hint list per client but a single `version` for the whole
--- buffer, and a change notification only refreshes the client that sent it
--- (`vim/lsp/inlay_hint.lua`). So with two hint-serving servers on one buffer
--- the fresher answer marks the state current while the other client's byte
--- columns still point into lines that have since shrunk, and the decoration
--- provider dies with "Invalid 'col': out of range". Dropping every answer but
--- the owner's keeps hints and version in step, which is what that code assumes.
local guarded = false
local function guard_inlay_hints()
  if guarded then
    return
  end
  guarded = true

  local upstream = vim.lsp.inlay_hint.on_inlayhint
  vim.lsp.inlay_hint.on_inlayhint = function(err, result, ctx)
    local bufnr = ctx and ctx.bufnr
    if not err and bufnr and vim.api.nvim_buf_is_loaded(bufnr) then
      local owner = hint_owner(bufnr)
      if owner and owner.id ~= ctx.client_id then
        return
      end
    end
    return upstream(err, result, ctx)
  end
end

--- Buffer-local keys, set when a server attaches. Buffer-local on purpose: in
--- a buffer with no server, `gd` and `K` keep their built-in meaning instead of
--- erroring or warning.
local function on_attach(buf)
  local map = u.buffmapper(buf)

  map("n", "gd", picker("lsp_definitions"), "Go to definition")
  map("n", "gr", picker("lsp_references"), "Find references")
  map("n", "gi", picker("lsp_implementations"), "Go to implementation")
  map("n", "gt", picker("lsp_type_definitions"), "Go to type definition")
  map("n", "gO", picker("lsp_document_symbols"), "Document symbols")
  map("n", "<leader>cs", picker("lsp_document_symbols"), "Document symbols")
  map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")

  map("n", "K", function()
    vim.lsp.buf.hover({ border = "single" })
  end, "Hover documentation")
  -- <C-k> stays window navigation.
  map("i", "<C-s>", function()
    vim.lsp.buf.signature_help({ border = "single" })
  end, "Signature help")

  map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code actions")
  map("n", "<leader>cr", vim.lsp.buf.rename, "Rename symbol")
end

--- Hints de inlay para un buffer que acaba de attachear.
---
--- Un segundo cliente que sirve hints puede quedarse con el buffer, asi que el
--- estado arranca de cero en vez de conservar las columnas del que perdio.
local function enable_inlay_hints(buf)
  if vim.lsp.inlay_hint.is_enabled({ bufnr = buf }) then
    vim.lsp.inlay_hint.enable(false, { bufnr = buf })
  end
  vim.lsp.inlay_hint.enable(true, { bufnr = buf })
end

--- Resalta las otras ocurrencias del simbolo bajo el cursor. Sin ventana, sin
--- panel, solo resaltado. El grupo se borra en LspDetach para no dejar
--- autocomandos colgando de un buffer sin servidor.
local function enable_document_highlight(buf)
  local group = u.augroup("lsp.highlight." .. buf)
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    buffer = buf,
    group = group,
    callback = vim.lsp.buf.document_highlight,
  })
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    buffer = buf,
    group = group,
    callback = vim.lsp.buf.clear_references,
  })
  vim.api.nvim_create_autocmd("LspDetach", {
    buffer = buf,
    once = true,
    callback = function()
      pcall(vim.api.nvim_del_augroup_by_id, group)
    end,
  })
end

--- El callback de LspAttach: teclas, hints y resaltado, segun lo que el
--- servidor que attacheo sepa hacer.
local function on_lsp_attach(event)
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if not client then
    return
  end

  on_attach(event.buf)

  if client:supports_method("textDocument/inlayHint") then
    enable_inlay_hints(event.buf)
  end

  if client:supports_method("textDocument/documentHighlight") then
    enable_document_highlight(event.buf)
  end
end

return {
  "neovim/nvim-lspconfig",
  -- VeryLazy, no BufReadPre: registrar los 11 servidores cuesta ~4 ms y no hay
  -- motivo para pagarlos antes de que el buffer se dibuje. `vim.lsp.enable()`
  -- hace `doautoall` sobre su propio FileType en cuanto `vim.v.vim_did_enter`
  -- es 1 (vim/lsp.lua), y VeryLazy dispara despues de VimEnter, asi que el
  -- servidor igual attachea al archivo que ya estaba abierto.
  event = "VeryLazy",
  -- No dependencies, deliberately. Neovim 0.12 reads lspconfig's lsp/*.lua
  -- straight off the runtimepath and never requires its Lua module, so this
  -- plugin is a directory of 418 server defaults rather than code. Mason is
  -- an installer, not a runtime dependency: having it here pulled mason.nvim
  -- (1.4 ms), mason-lspconfig (6.5 ms) and mason-registry into every single
  -- file opened, for nothing.
  config = function()
    guard_inlay_hints()
    -- Per-buffer behaviour, identical for every server: it only ever runs when
    -- one actually attaches, so it costs nothing when there is none.
    vim.api.nvim_create_autocmd("LspAttach", {
      group = u.augroup("lsp.attach"),
      desc = "Keys, inlay hints and document highlight",
      callback = on_lsp_attach,
    })
    lsp.register()
  end,
}

