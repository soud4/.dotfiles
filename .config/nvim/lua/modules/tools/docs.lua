--- The documentation browser.
---
--- Native floor: the config's own `docs/*.md` listed through `vim.ui.select`,
--- opened in a dedicated tab with conceal on, `gO` for the table of contents
--- (built in for markdown since 0.11) and `<CR>` to follow a link between
--- pages. No plugin is involved in reading the documentation; render-markdown
--- only makes the same buffers prettier.
---
--- `docs.root` is published as a `value` feature so a finder can offer a
--- previewing picker over the same directory without this module ever naming
--- Telescope, and without the finder knowing where the docs live.
local uv = vim.uv or vim.loop

local function root()
  return vim.fs.joinpath(vim.fn.stdpath("config"), "docs")
end

--- Whether a buffer is one of the documentation pages. The root README is one
--- of them: it is the entry point the picker offers first, and it should read
--- like every other page.
local function inside_docs(path)
  if not path or path == "" then
    return false
  end
  path = vim.fs.normalize(path)
  local dir = root()
  return path:sub(1, #dir) == dir
    or path == vim.fs.normalize(vim.fs.joinpath(vim.fn.stdpath("config"), "README.md"))
end

--- First `# heading` of a file, as its title. Read lazily, a few lines at a
--- time: the picker must not read every doc in full to draw a list.
local function title_of(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local title
  for _ = 1, 10 do
    local line = file:read("l")
    if not line then
      break
    end
    title = line:match("^#%s+(.+)$")
    if title then
      break
    end
  end
  file:close()
  return title
end

--- Every page, the root README first, then `docs/` in path order.
local function pages()
  local out = {}
  local config = vim.fn.stdpath("config")
  local readme = vim.fs.joinpath(config, "README.md")
  if uv.fs_stat(readme) then
    out[#out + 1] = { path = readme, rel = "README.md", title = title_of(readme) }
  end
  local found = vim.fn.globpath(root(), "**/*.md", false, true)
  table.sort(found)
  for _, path in ipairs(found) do
    out[#out + 1] = {
      path = path,
      rel = vim.fs.normalize(path):sub(#vim.fs.normalize(config) + 2),
      title = title_of(path),
    }
  end
  return out
end

-- Viewer --------------------------------------------------------------------

--- The documentation gets its own tab, reused across openings, so reading it
--- never disturbs the window layout you were working in.
local view_tab = nil

local function focus_tab()
  if view_tab and vim.api.nvim_tabpage_is_valid(view_tab) then
    vim.api.nvim_set_current_tabpage(view_tab)
    return
  end
  vim.cmd.tabnew()
  view_tab = vim.api.nvim_get_current_tabpage()
end

---@param path string
---@param opts { anchor?: string }|nil
local function open(path, opts)
  opts = opts or {}
  if not path or not uv.fs_stat(path) then
    return vim.notify(("no such documentation page: %s"):format(tostring(path)), vim.log.levels.WARN)
  end
  focus_tab()
  vim.cmd.edit(vim.fn.fnameescape(path))
  if opts.anchor then
    -- A heading whose text starts with the anchor, at any level. Silent and
    -- from the top, so a miss simply leaves the cursor where it was.
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
    pcall(vim.fn.search, ("^#\\+\\s\\+.*\\<%s\\>"):format(vim.fn.escape(opts.anchor, "\\")), "cW")
    vim.cmd("normal! zz")
  end
end

--- Follow a markdown link under the cursor. Relative `.md` targets open in the
--- viewer, anything with a scheme goes to `vim.ui.open`.
local function follow()
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local from = 1
  while true do
    local start, stop, target = line:find("%[[^%]]*%]%(([^)]+)%)", from)
    if not start then
      break
    end
    if col >= start and col <= stop then
      local file, anchor = target:match("^([^#]*)#?(.*)$")
      if file:match("^%a[%w+.-]*://") or file:match("^mailto:") then
        return vim.ui.open(file)
      end
      if file == "" then
        return open(vim.api.nvim_buf_get_name(0), { anchor = anchor:gsub("%-", " ") })
      end
      local base = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
      return open(vim.fs.normalize(vim.fs.joinpath(base, file)), {
        anchor = anchor ~= "" and anchor:gsub("%-", " ") or nil,
      })
    end
    from = stop + 1
  end
  -- No link here: fall back to what the key normally does.
  pcall(vim.cmd, "normal! gf")
end

--- Reading comfort and the local keys, for documentation buffers only. Set from
--- an autocommand rather than by the opener, so a page reached through a finder
--- or through `gf` behaves exactly like one opened from the picker.
local function prepare_buffer(buf)
  vim.opt_local.wrap = true
  vim.opt_local.linebreak = true
  vim.opt_local.breakindent = true
  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "no"
  vim.opt_local.colorcolumn = ""
  vim.opt_local.spell = false
  vim.opt_local.cursorline = true

  local function nmap(lhs, rhs, desc)
    vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, nowait = true, desc = desc })
  end
  nmap("<CR>", follow, "Follow documentation link")
  nmap("gf", follow, "Follow documentation link")
  nmap("<BS>", "<C-o>", "Back")
  -- `q` closes the viewer, except while a macro is being recorded: swallowing
  -- the only key that stops a recording would be a trap.
  vim.keymap.set("n", "q", function()
    if vim.fn.reg_recording() ~= "" then
      return "q"
    end
    vim.schedule(function()
      if view_tab and vim.api.nvim_tabpage_is_valid(view_tab) and #vim.api.nvim_list_tabpages() > 1 then
        vim.cmd.tabclose()
      else
        vim.cmd.bdelete()
      end
    end)
    return ""
  end, { buffer = buf, expr = true, silent = true, nowait = true, desc = "Close the documentation" })
end

--- Which page documents the file being edited: a module maps to its group page
--- with its own name as the anchor, a kernel file to the kernel page.
---@return string|nil path, string|nil anchor
local function page_for_current_file()
  local name = vim.fs.normalize(vim.api.nvim_buf_get_name(0))
  local group, module = name:match("lua/modules/([^/]+)/([^/]+)%.lua$")
  if group then
    return vim.fs.joinpath(root(), "modules", group .. ".md"), module
  end
  local kernel = name:match("lua/dohwa/(.+)%.lua$")
  if kernel then
    return vim.fs.joinpath(root(), "kernel.md"), (kernel:gsub("/init$", ""))
  end
  if name:match("lua/profiles/") then
    return vim.fs.joinpath(root(), "guides", "profiles-and-disabling.md"), nil
  end
  return nil
end

return {
  description = "Documentation browser",
  -- Ordering only: a markdown renderer wants the tree-sitter parser to be
  -- installed first, and works off the bundled one when it is not.
  optional = { "editor.syntax" },

  native = function(ctx)
    ctx:reserve("<leader>h", "Help & docs")

    ctx:declare("docs.root", {
      kind = "value",
      desc = "Where the documentation lives",
      native = function()
        return root()
      end,
    })

    ctx:declare("docs.index", {
      desc = "Open the documentation index",
      native = function()
        return function()
          local index = vim.fs.joinpath(root(), "README.md")
          open(uv.fs_stat(index) and index or vim.fs.joinpath(vim.fn.stdpath("config"), "README.md"))
        end
      end,
    })

    ctx:declare("docs.browse", {
      desc = "Browse the documentation",
      native = function()
        return function()
          local items = pages()
          if #items == 0 then
            return vim.notify("no documentation found in " .. root(), vim.log.levels.WARN)
          end
          vim.ui.select(items, {
            prompt = "Docs",
            format_item = function(item)
              return ("%-34s %s"):format(item.rel, item.title or "")
            end,
          }, function(choice)
            if choice then
              open(choice.path)
            end
          end)
        end
      end,
    })

    ctx:declare("docs.grep", {
      desc = "Search the documentation",
      native = function()
        return function()
          vim.ui.input({ prompt = "Search docs: " }, function(pattern)
            if not pattern or pattern == "" then
              return
            end
            local files = vim.fn.globpath(root(), "**/*.md", false, true)
            if #files == 0 then
              return vim.notify("no documentation found", vim.log.levels.WARN)
            end
            vim.cmd({
              cmd = "grep",
              args = vim.list_extend({ vim.fn.shellescape(pattern) }, files),
              bang = true,
            })
            if #vim.fn.getqflist() > 0 then
              vim.cmd.copen()
            else
              vim.notify("no matches in the documentation", vim.log.levels.INFO)
            end
          end)
        end
      end,
    })

    ctx:declare("docs.module", {
      desc = "Documentation for the file being edited",
      native = function()
        return function()
          local path, anchor = page_for_current_file()
          if not path then
            return vim.notify("this file has no documentation page", vim.log.levels.INFO)
          end
          open(path, { anchor = anchor })
        end
      end,
    })

    --- Conceal-based markdown rendering. The native floor is what Neovim can
    --- do alone: hide the link and emphasis markup. A renderer takes this over.
    ctx:declare("docs.render", {
      kind = "state",
      desc = "Markdown rendering",
      native = function()
        return function()
          ctx:autocmd("FileType", {
            group = ctx:augroup("conceal"),
            pattern = "markdown",
            desc = "Conceal markdown markup",
            callback = function()
              vim.opt_local.conceallevel = 2
              vim.opt_local.concealcursor = "nc"
            end,
          })
        end
      end,
    })

    ctx:autocmd("FileType", {
      group = ctx:augroup("buffer"),
      pattern = "markdown",
      desc = "Reading keys and layout for documentation buffers",
      callback = function(event)
        if inside_docs(vim.api.nvim_buf_get_name(event.buf)) then
          prepare_buffer(event.buf)
        end
      end,
    })

    ctx:slot("n", "<leader>hh", "docs.browse")
    ctx:slot("n", "<leader>hi", "docs.index")
    ctx:slot("n", "<leader>hg", "docs.grep")
    ctx:slot("n", "<leader>hm", "docs.module")

    ctx:toggle("m", "Toggle: markdown rendering", function()
      if package.loaded["render-markdown"] then
        return require("render-markdown").buf_toggle()
      end
      vim.opt_local.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
      vim.notify("conceal " .. (vim.wo.conceallevel == 0 and "off" or "on"))
    end)

    vim.api.nvim_create_user_command("Docs", function(cmd)
      if cmd.args == "" then
        return ctx:call("docs.browse")
      end
      for _, item in ipairs(pages()) do
        if item.rel == cmd.args or item.rel:gsub("%.md$", "") == cmd.args then
          return open(item.path)
        end
      end
      vim.notify(("no documentation page '%s'"):format(cmd.args), vim.log.levels.WARN)
    end, {
      nargs = "?",
      desc = "Open a documentation page",
      complete = function(lead)
        local out = {}
        for _, item in ipairs(pages()) do
          local name = item.rel:gsub("%.md$", "")
          if name:find(lead, 1, true) == 1 then
            out[#out + 1] = name
          end
        end
        return out
      end,
    })
  end,

  declare = function(ctx)
    -- render-markdown manages 'conceallevel' per window itself, so the native
    -- autocommand must not also set it.
    ctx:override("docs.render")
  end,

  plugins = function()
    return {
      {
        "MeanderingProgrammer/render-markdown.nvim",
        ft = { "markdown" },
        dependencies = { "nvim-tree/nvim-web-devicons" },
      },
    }
  end,

  setup = function(ctx)
    require("render-markdown").setup({
      completions = { lsp = { enabled = true } },
      heading = {
        sign = false,
        icons = { "# ", "## ", "### ", "#### ", "##### ", "###### " },
        width = "block",
        min_width = 40,
        left_pad = 0,
        right_pad = 2,
      },
      code = {
        sign = false,
        width = "block",
        min_width = 60,
        right_pad = 2,
        border = "thin",
        language_pad = 1,
      },
      bullet = { icons = { "•", "◦", "▪", "▫" } },
      checkbox = {
        unchecked = { icon = "󰄱 " },
        checked = { icon = "󰱒 " },
      },
      pipe_table = { preset = "round", style = "full" },
      quote = { icon = "▌" },
      link = { hyperlink = "󰌷 ", image = "󰥶 ", email = "󰀓 " },
      -- Reveal the raw markup on the line the cursor is on, so the file stays
      -- editable rather than becoming a read-only rendering.
      anti_conceal = { enabled = true, above = 0, below = 0 },
      win_options = { showbreak = { default = "", rendered = "  " } },
      overrides = {
        buftype = { nofile = { enabled = false } },
      },
    })
    ctx:log("render-markdown active")
  end,
}
