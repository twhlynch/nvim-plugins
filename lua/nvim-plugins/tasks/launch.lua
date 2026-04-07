local M = {}

local consts = require("nvim-plugins.tasks.consts")
local tasks = require("nvim-plugins.tasks.tasks")
local utils = require("nvim-plugins.tasks.utils")

---build command for a launch config
---@param config LaunchConfig
---@param inputs table<string, UserInput>
---@param env env
---@return command | nil
function M.build_cmd(config, inputs, env)
	local exec = config.runtimeExecutable or config.program
	if not exec then
		vim.notify(consts.strings.missing_program, vim.log.levels.ERROR)
		return nil
	end

	local cmd = utils.build_cmd(exec, config.args, inputs, env)
	return cmd
end

---run a launch config
---@param config LaunchConfig
---@param global_state PluginState
function M.run(config, global_state)
	local commands = {}

	local env = utils.build_env(config.env or vim.fn.environ(), global_state.project_inputs)
	local cwd = utils.resolve_vars(config.cwd, global_state.project_inputs, env) or vim.fn.getcwd()

	-- queue preLaunchTask entry
	if config.preLaunchTask then
		local pre_task = global_state.project_tasks[config.preLaunchTask]
		if pre_task then
			local pre_cmd = tasks.build_cmd(pre_task, global_state.project_inputs, env)
			if pre_cmd then
				table.insert(commands, pre_cmd)
			end
		else
			vim.notify(vim.fn.printf(consts.strings.task_not_found, config.preLaunchTask), vim.log.levels.WARN)
		end
	end

	-- queue actual launch command
	local launch_cmd = M.build_cmd(config, global_state.project_inputs, env)
	if launch_cmd then
		table.insert(commands, launch_cmd)
	end

	if #commands == 0 then
		return
	end

	utils.execute_commands(commands, env, cwd)
end

return M
