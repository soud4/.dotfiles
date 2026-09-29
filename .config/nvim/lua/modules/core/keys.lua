--- The only module that owns global keys.
---
--- Global keys are bound to *Features*, never to implementations. A module
--- competes by implementing `goto.definition`; it never names `gd`. That is why
--- no module can collide with another on a global key: it has no way to ask for
--- one. Rebinding `gd` for the whole config is a single line here.
---
--- Every Feature declared below carries a priority-0 native implementation, so
--- these keys keep working with every plugin switched off.
local function has_lsp(method)
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if not method or client:supports_method(method) then
      return true
    end
  end
  return false
end

--- Reach vim.lsp.buf lazily. Indexing it while declaring features would pull
--- the whole LSP stack into the startup path -- around 7 ms -- for keys that may
--- never be pressed in a session. The whole point of a thunk is that nothing is
--- resolved until it is used, and passing `vim.lsp.buf.definition` as an
--- argument resolves it immediately.
---@param method string
---@param opts table|nil
local function lsp_buf(method, opts)
  return function()
    return vim.lsp.buf[method](opts)
  end
end

--- Use the LSP when a server is attached, otherwise the built-in behaviour.
--- `normal!` bypasses mappings, so this never recurses into our own slot.
local function lsp_or_builtin(lsp_fn, builtin)
  return function()
    return function()
      if has_lsp() then
        lsp_fn()
      elseif builtin then
        vim.cmd("normal! " .. builtin)
      end
    end
  end
end

local function lsp_only(lsp_fn, what)
  return function()
    return function()
      if not has_lsp() then
        return vim.notify(("no language server attached: %s unavailable"):format(what), vim.log.levels.WARN)
      end
      lsp_fn()
    end
  end
end

return {
  description = "Global keys and universal features",

  native = function(ctx)
    ------------------------------------------------------------------------
    -- Universal features. The core owns the declaration and the native floor;
    -- modules only add better implementations at a higher priority.
    ------------------------------------------------------------------------
    ctx:declare("goto.definition", {
      desc = "Go to definition",
      native = lsp_or_builtin(lsp_buf("definition"), "gd"),
    })
    ctx:declare("goto.declaration", {
      desc = "Go to declaration",
      native = lsp_or_builtin(lsp_buf("declaration"), "gD"),
    })
    ctx:declare("goto.implementation", {
      desc = "Go to implementation",
      native = lsp_only(lsp_buf("implementation"), "implementations"),
    })
    ctx:declare("goto.type_definition", {
      desc = "Go to type definition",
      native = lsp_only(lsp_buf("type_definition"), "type definitions"),
    })
    ctx:declare("goto.references", {
      desc = "Find references",
      -- Without a server, a project grep into the quickfix list is the honest
      -- native equivalent.
      native = function()
        return function()
          if has_lsp() then
            return vim.lsp.buf.references()
          end
          local word = vim.fn.expand("<cword>")
          if word == "" then
            return
          end
          vim.cmd({ cmd = "grep", args = { vim.fn.shellescape(word) }, bang = true })
          vim.cmd.copen()
        end
      end,
    })
    ctx:declare("doc.hover", {
      desc = "Hover documentation",
      native = lsp_or_builtin(lsp_buf("hover", { border = ctx.ui.border }), "K"),
    })
    ctx:declare("doc.signature", {
      desc = "Signature help",
      native = lsp_only(lsp_buf("signature_help", { border = ctx.ui.border }), "signature help"),
    })
    ctx:declare("symbols.document", {
      desc = "Document symbols",
      native = lsp_only(lsp_buf("document_symbol"), "document symbols"),
    })
    ctx:declare("code.action", {
      desc = "Code actions",
      native = lsp_only(lsp_buf("code_action"), "code actions"),
    })
    ctx:declare("code.rename", {
      desc = "Rename symbol",
      native = lsp_only(lsp_buf("rename"), "rename"),
    })

    -- Diagnostics are entirely native: nothing here needs a plugin.
    ctx:declare("diagnostic.current", {
      desc = "Show diagnostic under the cursor",
      native = function()
        return vim.diagnostic.open_float
      end,
    })
    ctx:declare("diagnostic.next", {
      desc = "Next diagnostic",
      native = function()
        return function()
          vim.diagnostic.jump({ count = 1, float = true })
        end
      end,
    })
    ctx:declare("diagnostic.prev", {
      desc = "Previous diagnostic",
      native = function()
        return function()
          vim.diagnostic.jump({ count = -1, float = true })
        end
      end,
    })
    ctx:declare("diagnostic.list", {
      desc = "List diagnostics",
      native = function()
        return function()
          vim.diagnostic.setqflist()
        end
      end,
    })

    ------------------------------------------------------------------------
    -- Insert-mode navigation. <Tab> is a global key, so it belongs to a slot:
    -- the completion module competes for it by implementing the feature, and
    -- the native version already drives the built-in popup menu and the native
    -- snippet expansion from vim.snippet.
    ------------------------------------------------------------------------
    -- The 'i' flag matters: without it the keys land at the *end* of the
    -- typeahead queue, after whatever the user has already typed, and a plain
    -- <Tab> silently disappears.
    local function feed(keys)
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "ni", false)
    end

    ctx:declare("completion.next", {
      desc = "Next completion item / jump forward in snippet",
      native = function()
        return function()
          if vim.fn.pumvisible() == 1 then
            return feed("<C-n>")
          end
          if vim.snippet.active({ direction = 1 }) then
            return vim.snippet.jump(1)
          end
          feed("<Tab>")
        end
      end,
    })
    ctx:declare("completion.prev", {
      desc = "Previous completion item / jump back in snippet",
      native = function()
        return function()
          if vim.fn.pumvisible() == 1 then
            return feed("<C-p>")
          end
          if vim.snippet.active({ direction = -1 }) then
            return vim.snippet.jump(-1)
          end
          feed("<S-Tab>")
        end
      end,
    })

    ctx:declare("format.buffer", {
      desc = "Format buffer",
      native = function()
        return function()
          if has_lsp("textDocument/formatting") then
            return vim.lsp.buf.format({ async = true })
          end
          if vim.bo.formatprg ~= "" or vim.o.formatprg ~= "" then
            return vim.cmd("normal! gggqG``")
          end
          vim.notify("no formatter available for this buffer", vim.log.levels.WARN)
        end
      end,
    })

    ------------------------------------------------------------------------
    -- Neovim 0.11 ships gr-prefixed LSP mappings (grn, gra, grr, gri, grt).
    -- This config binds `gr` itself, which would make every one of them wait
    -- for 'timeoutlen'. Removing them keeps `gr` instant.
    ------------------------------------------------------------------------
    for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt" }) do
      for _, mode in ipairs({ "n", "x" }) do
        pcall(vim.keymap.del, mode, lhs)
      end
    end

    ------------------------------------------------------------------------
    -- Global slots: key -> feature.
    ------------------------------------------------------------------------
    ctx:slot("n", "gd", "goto.definition")
    ctx:slot("n", "gD", "goto.declaration")
    ctx:slot("n", "gr", "goto.references")
    ctx:slot("n", "gi", "goto.implementation")
    ctx:slot("n", "gt", "goto.type_definition")
    ctx:slot("n", "gO", "symbols.document")
    ctx:slot("n", "K", "doc.hover")
    ctx:slot("i", "<C-s>", "doc.signature") -- <C-k> stays window navigation
    ctx:slot({ "i", "s" }, "<Tab>", "completion.next")
    ctx:slot({ "i", "s" }, "<S-Tab>", "completion.prev")
    ------------------------------------------------------------------------
    -- `]` and `[` are a shared namespace, like <leader>t: modules ask for a
    -- letter through ctx:jump() and the broker refuses a second taker.
    ------------------------------------------------------------------------
    -- Normal and visual only: `[` and `]` are ordinary characters in insert
    -- mode, where editor.pairs reserves them.
    local jump_modes = { "n", "x", "o" }
    ctx:reserve("]", "Next", { jumps = { "]", "[" }, modes = jump_modes })
    ctx:reserve("[", "Previous", { modes = jump_modes })

    -- Same idea for text objects: `a`/`i` in operator-pending and visual modes.
    ctx:reserve("a", "A text object", { modes = { "o", "x" }, textobjects = { "a", "i" } })
    ctx:reserve("i", "Inner text object", { modes = { "o", "x" } })
    ctx:jump("d", "diagnostic", {
      next = function()
        ctx:call("diagnostic.next")
      end,
      prev = function()
        ctx:call("diagnostic.prev")
      end,
    })

    ctx:reserve("<leader>d", "Diagnostics")
    ctx:slot("n", "<leader>dd", "diagnostic.current")
    ctx:slot("n", "<leader>dl", "diagnostic.list")

    ctx:declare("search.buffer", {
      desc = "Search inside this file",
      native = function()
        return function()
          vim.api.nvim_feedkeys("/", "ni", false)
        end
      end,
    })
    ctx:slot("n", "<leader>/", "search.buffer")

    ctx:reserve("<leader>=", "Format")
    ctx:slot({ "n", "v" }, "<leader>==", "format.buffer")

    ------------------------------------------------------------------------
    -- Plain editing keys. These belong to no feature: there is nothing a
    -- plugin could reasonably want to override about them.
    ------------------------------------------------------------------------
    ctx:map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

    ctx:map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
    ctx:map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
    ctx:map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
    ctx:map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

    ctx:map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move selection down" })
    ctx:map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move selection up" })

    ctx:map("n", "<C-d>", "<C-d>zz", { desc = "Half page down, centred" })
    ctx:map("n", "<C-u>", "<C-u>zz", { desc = "Half page up, centred" })
    ctx:map("n", "n", "nzzzv", { desc = "Next match, centred" })
    ctx:map("n", "N", "Nzzzv", { desc = "Previous match, centred" })

    -- Native project navigation: the floor under tools.finder.
    ctx:reserve("<leader>F", "Native find")
    ctx:map("n", "<leader>Ff", ":find ", { desc = "Find file (:find)", silent = false })
    ctx:map("n", "<leader>Fg", ":silent grep! ", { desc = "Grep project (:grep)", silent = false })
    ctx:map("n", "<leader>Fb", ":buffer ", { desc = "Switch buffer", silent = false })
  end,
}
