--- Statusline.
---
--- The native implementation is a real statusline, not a placeholder: mode,
--- file, git branch, diagnostics, attached servers, filetype and position. It
--- is what `laststatus=3` shows when lualine is not installed.
---
--- Git counts come from the `git.diffstat` feature when something provides it,
--- so the branch and the +/~/- figures simply disappear with tools.git off
--- instead of erroring.
local M = {}

local ui = require("core.ui")

local MODES = {
  n = "NORMAL", no = "OP-PENDING", v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK",
  s = "SELECT", S = "S-LINE", ["\19"] = "S-BLOCK", i = "INSERT", ic = "INSERT",
  R = "REPLACE", Rv = "V-REPLACE", c = "COMMAND", cv = "EX", r = "PROMPT",
  rm = "MORE", ["r?"] = "CONFIRM", ["!"] = "SHELL", t = "TERMINAL",
}

local branch_cache = {}

--- Read the current branch straight from `.git/HEAD`.
---
--- Cached on the buffer's directory, and the cache is consulted *before*
--- `vim.fs.root`, not after. Locating the repository root means stat()ing every
--- directory up to `/`, which measured at 12.9 us -- roughly 70% of the cost of
--- rendering this statusline -- and it was running on every single redraw.
local function branch(path)
  local dir = path ~= "" and vim.fs.dirname(path) or vim.uv.cwd()
  local cached = branch_cache[dir]
  if cached and (vim.uv.now() - cached.at) < 2000 then
    return cached.name
  end

  local name = ""
  local root = vim.fs.root(dir, ".git")
  if root then
    local head = io.open(vim.fs.joinpath(root, ".git", "HEAD"), "r")
    if head then
      local line = head:read("*l") or ""
      head:close()
      name = line:match("ref: refs/heads/(.+)$") or line:sub(1, 7)
    end
  end
  branch_cache[dir] = { name = name, at = vim.uv.now() }
  return name
end

local function diagnostics()
  local counts = vim.diagnostic.count(0)
  local parts = {}
  for _, item in ipairs({
    { vim.diagnostic.severity.ERROR, ui.icons.severity.error, "DiagnosticError" },
    { vim.diagnostic.severity.WARN, ui.icons.severity.warn, "DiagnosticWarn" },
    { vim.diagnostic.severity.INFO, ui.icons.severity.info, "DiagnosticInfo" },
    { vim.diagnostic.severity.HINT, ui.icons.severity.hint, "DiagnosticHint" },
  }) do
    local n = counts[item[1]] or 0
    if n > 0 then
      parts[#parts + 1] = ("%%#%s#%s%d%%*"):format(item[3], item[2], n)
    end
  end
  return table.concat(parts, " ")
end

local function servers()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    names[#names + 1] = client.name
  end
  if #names == 0 then
    return ""
  end
  return ui.icons.ui.lsp .. table.concat(names, ", ")
end

--- Called by 'statusline' through v:lua on every redraw.
function M.render()
  local dohwa = require("dohwa")
  local left = {
    ("%%#StatusLineMode# %s %s %%*"):format(ui.icons.ui.mode, MODES[vim.api.nvim_get_mode().mode] or "?"),
    " %t%{&modified?'" .. ui.icons.file.modified .. "':''}%{&readonly?'" .. ui.icons.file.readonly .. "':''}",
  }

  local head = branch(vim.api.nvim_buf_get_name(0))
  if head ~= "" then
    left[#left + 1] = (" %s %s"):format(ui.icons.git.branch, head)
  end
  local stat = dohwa.registry and dohwa.registry:value("git.diffstat", nil)
  if stat then
    local parts = {}
    for _, item in ipairs({
      { stat.added, ui.icons.git.added },
      { stat.changed, ui.icons.git.modified },
      { stat.removed, ui.icons.git.removed },
    }) do
      if (item[1] or 0) > 0 then
        parts[#parts + 1] = item[2] .. item[1]
      end
    end
    if #parts > 0 then
      left[#left + 1] = " " .. table.concat(parts, " ")
    end
  end

  local right = {}
  local diag = diagnostics()
  if diag ~= "" then
    right[#right + 1] = diag
  end
  local lsp = servers()
  if lsp ~= "" then
    right[#right + 1] = lsp
  end
  right[#right + 1] = ("%s%s"):format(ui.icons.ui.folder, vim.fn.fnamemodify(vim.uv.cwd() or "", ":t"))
  right[#right + 1] = vim.bo.filetype ~= "" and vim.bo.filetype or "―"
  right[#right + 1] = ("%s%%l:%%v"):format(ui.icons.ui.position)

  return table.concat(left) .. "%=" .. table.concat(right, "  ") .. " "
end

M.description = "Statusline"

M.native = function(ctx)
  ctx:declare("ui.statusline", {
    kind = "state",
    desc = "Statusline",
    native = function()
      return function()
        vim.api.nvim_set_hl(0, "StatusLineMode", { link = "Visual", default = true })
        vim.o.statusline = "%!v:lua.require'modules.ui.statusline'.render()"
      end
    end,
  })
  -- Declared here because this is what consumes it; tools.git implements it.
  ctx:declare("git.diffstat", {
    kind = "value",
    desc = "Added/changed/removed line counts",
    optional = true,
  })
end

M.declare = function(ctx)
  ctx:implement("ui.statusline", 50, function()
    return function()
      require("lualine").setup(require("modules.ui.statusline").lualine_opts(ctx.ui))
    end
  end)
end

M.plugins = function()
  return {
    {
      "nvim-lualine/lualine.nvim",
      lazy = false,
      dependencies = { "nvim-tree/nvim-web-devicons" },
    },
  }
end

--- The lualine configuration, kept beside the native one so both render the
--- same information in the same order.
function M.lualine_opts(icons)
  local function lsp_clients()
    local names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      names[#names + 1] = client.name
    end
    return #names > 0 and (icons.icons.ui.lsp .. table.concat(names, ", ")) or ""
  end

  return {
    options = {
      theme = "auto",
      component_separators = "",
      section_separators = "",
      icons_enabled = true,
      globalstatus = true,
      disabled_filetypes = { statusline = { "dashboard", "alpha", "neo-tree", "NvimTree" } },
    },
    sections = {
      lualine_a = {
        { "mode", fmt = function(s) return icons.icons.ui.mode .. " " .. s end, padding = { left = 1, right = 1 } },
      },
      lualine_b = {
        {
          "filename",
          file_status = true,
          path = 0,
          symbols = {
            modified = icons.icons.file.modified,
            readonly = icons.icons.file.readonly,
            unnamed = icons.icons.file.unnamed,
          },
        },
        { "branch", icon = icons.icons.git.branch },
        {
          "diff",
          symbols = {
            added = icons.icons.git.added,
            modified = icons.icons.git.modified,
            removed = icons.icons.git.removed,
          },
        },
      },
      lualine_c = {},
      lualine_x = {
        {
          "diagnostics",
          sources = { "nvim_diagnostic" },
          symbols = {
            error = icons.icons.severity.error,
            warn = icons.icons.severity.warn,
            info = icons.icons.severity.info,
            hint = icons.icons.severity.hint,
          },
        },
        { lsp_clients, color = { gui = "bold" } },
        {
          function()
            return icons.icons.ui.folder .. vim.fn.fnamemodify(vim.uv.cwd() or "", ":t")
          end,
        },
      },
      lualine_y = { { "filetype", colored = true } },
      lualine_z = {
        {
          function()
            return ("%s%d:%d"):format(icons.icons.ui.position, vim.fn.line("."), vim.fn.virtcol("."))
          end,
        },
      },
    },
  }
end

return M
