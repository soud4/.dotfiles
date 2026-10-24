--- Devcontainers vía @devcontainers/cli.

local M = {}

-- docker o podman, el que tengas
local engine = vim.fn.executable("podman") == 1 and "podman" or "docker"

local function ws()
	return vim.fn.shellescape(vim.fn.getcwd())
end

local function term(cmd)
	vim.cmd("botright split | resize 15")
	vim.cmd.terminal(cmd)
	vim.cmd.startinsert()
end

local function cli(sub, extra)
	if vim.fn.executable("devcontainer") == 0 then
		vim.notify("devcontainer CLI no encontrado (npm i -g @devcontainers/cli)", vim.log.levels.ERROR)
		return
	end
	if not vim.uv.fs_stat(vim.fs.joinpath(vim.fn.getcwd(), ".devcontainer")) then
		vim.notify("No hay .devcontainer/ en " .. vim.fn.getcwd(), vim.log.levels.WARN)
		return
	end
	term(("devcontainer %s --docker-path %s --workspace-folder %s %s"):format(sub, engine, ws(), extra or ""))
end

-- El CLI etiqueta los contenedores con la carpeta del proyecto
local function by_folder()
	return ("$(%s ps -aq --filter label=devcontainer.local_folder=%s)"):format(engine, ws())
end

local cmds = {
	DevUp = function()
		cli("up")
	end,
	DevRebuild = function()
		cli("up", "--remove-existing-container")
	end,
	DevShell = function()
		cli("exec", "sh")
	end,
	DevNvim = function()
		cli("exec", "nvim")
	end,
	DevStop = function()
		term(engine .. " stop " .. by_folder())
	end,
	DevDelete = function()
		term(engine .. " rm -f " .. by_folder())
	end,
}

function M.setup()
	for name, fn in pairs(cmds) do
		vim.api.nvim_create_user_command(name, fn, {})
	end
	local map = function(lhs, cmd, desc)
		vim.keymap.set("n", lhs, "<cmd>" .. cmd .. "<cr>", { desc = desc })
	end
	map("<leader>Du", "DevUp", "Up")
	map("<leader>Dr", "DevRebuild", "Rebuild")
	map("<leader>Ds", "DevShell", "Shell")
	map("<leader>Dn", "DevNvim", "Nvim dentro")
	map("<leader>Dx", "DevStop", "Stop")
	map("<leader>Dd", "DevDelete", "Delete")
end

return M
