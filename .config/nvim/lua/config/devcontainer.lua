-- Devcontainer helpers using @devcontainers/cli.
local M = {}

-- Use podman if installed, otherwise docker.
local engine = vim.fn.executable("podman") == 1 and "podman" or "docker"

-- Run a command in a terminal split at the bottom.
-- `new` opens an empty buffer, so termopen doesn't hijack the current file.
local function term(cmd)
  vim.cmd("botright 15new")
  vim.fn.termopen(cmd)
  vim.cmd.startinsert()
end

-- Build the base `devcontainer` command for the current project.
-- Options like --docker-path and --workspace-folder must precede
-- any positional arguments (e.g. for `devcontainer exec <cmd>`).
local function dc(subcmd, cmd_args)
  local dir = vim.fn.shellescape(vim.fn.getcwd())
  local base = string.format("devcontainer %s --docker-path %s --workspace-folder %s", subcmd, engine, dir)
  if cmd_args and cmd_args ~= "" then
    return base .. " " .. cmd_args
  end
  return base
end

-- Find containers of this project by the label the CLI adds.
local function ids()
  local dir = vim.fn.shellescape(vim.fn.getcwd())
  return string.format("$(%s ps -aq --filter label=devcontainer.local_folder=%s)", engine, dir)
end

function M.setup()
  local map = function(lhs, cmd, desc)
    vim.keymap.set("n", "<leader>D" .. lhs, function()
      term(cmd())
    end, { desc = desc })
  end

  map("u", function()
    return dc("up")
  end, "Devcontainer up")
  map("r", function()
    return dc("up --remove-existing-container")
  end, "Devcontainer rebuild")
  -- `up` first so the shell works even if the container is stopped.
  -- Its JSON result goes to /dev/null; build progress and errors use
  -- stderr, so they still show if something fails.
  map("s", function()
    return dc("up") .. " > /dev/null && " .. dc("exec", "sh")
  end, "Devcontainer shell")
  map("x", function()
    return engine .. " stop " .. ids()
  end, "Devcontainer stop")
  map("d", function()
    return engine .. " rm -f " .. ids()
  end, "Devcontainer delete")
end

return M
