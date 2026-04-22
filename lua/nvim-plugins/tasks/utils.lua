local M = {}

local consts = require("nvim-plugins.tasks.consts")

-- single terminal state across both runners
local term_state = {
	---@type integer | nil
	buf = nil,
	---@type integer | nil
	win = nil,
}

---build a command string or array from a command and args
---@param command string
---@param args? string[]
---@param inputs UserInput
---@param env env
---@return command
function M.build_cmd(command, args, inputs, env)
	local cmd = { M.resolve_vars(command, inputs, env) }

	if args == nil or #args == 0 then
		-- just the command as a string
		return cmd[1]
	else
		-- add each argument
		for _, arg in ipairs(args) do
			table.insert(cmd, M.resolve_vars(arg, inputs, env))
		end
	end

	-- list of command and args
	return cmd
end

---resolve vscode, input, and env variables in a string
---@param str string
---@param inputs table<string, UserInput>
---@param env env
---@return string | nil
function M.resolve_vars(str, inputs, env)
	if not str then
		return nil
	end

	 -- stylua: ignore
	local replacements = {
		["${workspaceFolder}"] =         vim.fn.getcwd(),
		["${file}"] =                    vim.fn.expand("%:p"),
		["${fileDirname}"] =             vim.fn.expand("%:p:h"),
		["${fileBasename}"] =            vim.fn.expand("%:t"),
		["${fileBasenameNoExtension}"] = vim.fn.expand("%:t:r"),
		["${workspaceFolderBasename}"] = vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
	}

	for pattern, replacement in pairs(replacements) do
		str = str:gsub(vim.pesc(pattern), replacement)
	end

	-- env variables
	str = str:gsub("$([%w_]+)", function(env_var)
		return env[env_var] or ""
	end)

	-- find an input option
	str = str:gsub("${input:([^}]+)}", function(id)
		local input = inputs[id]
		if not input then
			return ""
		end

		if input.type == "promptString" then
			return vim.fn.input((input.description or id) .. ": ", input.default or "")
		end
		return ""
	end)

	return str
end

---resolve variables in env and add to a merged env
---@param source_env env
---@param inputs table<string, UserInput>
---@return env
function M.build_env(source_env, inputs)
	---@type env
	local merged = vim.fn.environ()

	for k, v in pairs(source_env) do
		merged[k] = M.resolve_vars(v, inputs, merged)
	end

	return merged
end

---recreate terminal buffer and show in window
---@return integer | nil
function M.open_terminal()
	if term_state.buf and vim.api.nvim_buf_is_valid(term_state.buf) then
		vim.api.nvim_buf_delete(term_state.buf, { force = true })
	end

	term_state.buf = vim.api.nvim_create_buf(false, true)
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	local row = math.floor((vim.o.lines - height) / 2)
	local col = math.floor((vim.o.columns - width) / 2)

	if not (term_state.win and vim.api.nvim_win_is_valid(term_state.win)) then
		term_state.win = vim.api.nvim_open_win(term_state.buf, true, {
			relative = "editor",
			width = width,
			height = height,
			row = row,
			col = col,
			style = "minimal",
			border = "rounded",
			title = consts.strings.term_title,
			title_pos = "center",
		})
	else
		vim.api.nvim_win_set_buf(term_state.win, term_state.buf)
		vim.api.nvim_set_current_win(term_state.win)
	end

	vim.bo[term_state.buf].bufhidden = "wipe"
	return term_state.buf
end

---sequentially executes a list of commands
---@param cmds command[]
---@param env env
---@param cwd string
function M.execute_commands(cmds, env, cwd)
	local current_idx = 1

	local function run_next()
		local cmd = cmds[current_idx]
		if not cmd then
			return
		end

		M.open_terminal()
		local job_opts = {
			env = env,
			term = true,
		}
		if cwd then
			job_opts.cwd = cwd
		end

		if current_idx < #cmds then
			job_opts.on_exit = function(_, exit_code)
				if exit_code == 0 then
					current_idx = current_idx + 1
					vim.defer_fn(run_next, 50) -- yield to UI before next
				else
					vim.notify(vim.fn.printf(consts.strings.task_failed, exit_code), vim.log.levels.ERROR)
				end
			end
		end

		vim.fn.jobstart(cmd, job_opts)
		vim.cmd("startinsert")
	end

	run_next()
end

return M
