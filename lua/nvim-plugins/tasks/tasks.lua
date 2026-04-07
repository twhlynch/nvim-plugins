local M = {}

local consts = require("nvim-plugins.tasks.consts")
local utils = require("nvim-plugins.tasks.utils")

---build command for a task config
---@param config TaskConfig
---@param inputs table<string, UserInput>
---@param env env
---@return command | nil
function M.build_cmd(config, inputs, env)
	if not config.command then
		vim.notify(consts.strings.missing_command, vim.log.levels.ERROR)
		return nil
	end

	local cmd = utils.build_cmd(config.command, config.args, inputs, env)
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
