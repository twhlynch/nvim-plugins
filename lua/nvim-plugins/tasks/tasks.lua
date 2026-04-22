local M = {}

local consts = require("nvim-plugins.tasks.consts")
local utils = require("nvim-plugins.tasks.utils")

---build command for a task config
---@param config TaskConfig
---@param inputs table<string, UserInput>
---@param env env
---@return command | nil
function M.build_cmd(config, inputs, env)
	local command, args = nil, nil

	if config.type == "npm" then
		if not config.script then
			vim.notify(consts.strings.missing_script, vim.log.levels.ERROR)
			return nil
		end
		command = "npm"
		args = vim.list_extend({ "run", config.script }, config.args or {})
	elseif config.type == "shell" or config.type == "process" then
		if not config.command then
			vim.notify(consts.strings.missing_command, vim.log.levels.ERROR)
			return nil
		end
		command = config.command
		args = config.args
	end

	if not command then
		return nil
	end
	local cmd = utils.build_cmd(command, args, inputs, env)
	return cmd
end

---run a task config
---@param task TaskConfig
---@param global_state PluginState
function M.run(task, global_state)
	local env = utils.build_env({}, global_state.project_inputs)
	local cwd = vim.fn.getcwd()

	if task.options then
		if task.options.env then
			env = utils.build_env(task.options.env, global_state.project_inputs)
		end
		if task.options.cwd then
			cwd = utils.resolve_vars(task.options.cwd, global_state.project_inputs, env) or cwd
		end
	end

	local cmd = M.build_cmd(task, global_state.project_inputs, env)
	if cmd == nil then
		return
	end

	utils.execute_commands({ cmd }, env, cwd)
end

return M
