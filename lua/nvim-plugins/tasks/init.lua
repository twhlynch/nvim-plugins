local M = {}

local consts = require("nvim-plugins.tasks.consts")

---@type Opts
local options = {
	keybind = "<leader><CR>",
	sign_icon = "▶",
	sign_hl = "DiagnosticFloatingOk",
}

-- global cache so launch.json can access tasks.json for preLaunchTasks
-- TODO: replace this with dynamically loading tasks.json
---
---@type PluginState
M.state = {
	project_tasks = {},
	project_inputs = {},
}

---safely strip json comments without breaking urls
---@param content string
---@return string
local function strip_json_comments(content)
	return (
		content
			:gsub("://", "___URL_PROTOCOL___") -- save urls
			:gsub("//.-\n", "\n") -- line comments
			:gsub("/%*.-%*/", "") -- multiline comments
			:gsub("___URL_PROTOCOL___", "://") -- restore urls
	)
end

---remove trailing commas from json
---@param content string
---@return string
local function normalise_json_commas(content)
	-- remove commas from , } and , ]
	return (content:gsub(",%s*}", "}"):gsub(",%s*%]", "]"))
end

-- parse a jsonc buffer to a json table
---@param bufnr integer
---@return nil | table
local function parse_json(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(lines, "\n")
	content = strip_json_comments(content)
	content = normalise_json_commas(content)

	local ok, data = pcall(vim.json.decode, content)
	if not ok then
		return nil
	end

	if type(data) ~= "table" then
		return nil
	end

	return data
end

-- utility to find the line number of a specific key-value pair
---@param bufnr integer
---@param key string
---@param value string
---@return number | nil
local function find_line(bufnr, key, value)
	local pattern = '"' .. vim.pesc(key) .. '"%s*:%s*"' .. vim.pesc(value) .. '"'

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	for i, l in ipairs(lines) do
		if l:match(pattern) then
			return i
		end
	end

	return nil
end

---extract inputs into a mapping
---@param data TasksJson
---@return table<string, UserInput>
local function extract_inputs(data)
	local map = {}
	if data and data.inputs then
		for _, input in ipairs(data.inputs) do
			map[input.id] = input
		end
	end
	return map
end

---setup plugin for a config file buffer
---@param bufnr number
function M.attach(bufnr)
	vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
	local path = vim.api.nvim_buf_get_name(bufnr)
	local data = parse_json(bufnr)

	if not data then
		return
	end

	local is_tasks = path:match("tasks%.json$")
	local is_launch = path:match("launch%.json$")

	if is_tasks and data.version ~= consts.tasks_version then
		---@diagnostic disable-next-line: redundant-parameter
		vim.notify(vim.fn.printf(consts.strings.bad_version, data.version, consts.tasks_version), vim.log.levels.WARN)
	end
	if is_launch and data.version ~= consts.launch_version then
		---@diagnostic disable-next-line: redundant-parameter
		vim.notify(vim.fn.printf(consts.strings.bad_version, data.version, consts.launch_version), vim.log.levels.WARN)
	end

	local buffer_inputs = extract_inputs(data)
	local entries = {}

	-- update global inputs cache
	M.state.project_inputs = vim.tbl_deep_extend("force", M.state.project_inputs, buffer_inputs)

	if is_tasks and data.tasks then
		for _, task in ipairs(data.tasks) do
			if task.label then
				-- cache globally for preLaunchTask
				M.state.project_tasks[task.label] = task
				local lnum = find_line(bufnr, "label", task.label)
				if lnum then
					table.insert(entries, { type = "task", data = task, lnum = lnum })
				end
			end
		end
	elseif is_launch and data.configurations then
		for _, config in ipairs(data.configurations) do
			if config.name then
				local lnum = find_line(bufnr, "name", config.name)
				if lnum then
					table.insert(entries, { type = "launch", data = config, lnum = lnum })
				end
			end
		end
	end

	-- refresh signs
	vim.fn.sign_unplace(consts.sign_group, { buffer = bufnr })
	for i, e in ipairs(entries) do
		vim.fn.sign_place(i, consts.sign_group, consts.sign_name, bufnr, {
			lnum = e.lnum,
			priority = 10,
		})
	end

	-- store runnables in buffer state
	vim.b[bufnr].vscode_runner = {
		entries = entries,
		inputs = buffer_inputs,
	}

	-- attach keymap
	vim.keymap.set("n", options.keybind, function()
		M.run(bufnr)
	end, { buf = bufnr, desc = consts.strings.keybind_desc })
end

---run a config in a buffer
---@param bufnr integer
function M.run(bufnr)
	-- get line
	local line = vim.api.nvim_win_get_cursor(0)[1]
	-- get runners from buffer
	local runner_state = vim.b[bufnr].vscode_runner
	if not runner_state then
		return
	end

	-- get runner by line
	for _, e in ipairs(runner_state.entries) do
		if e.lnum == line then
			if e.type == "task" then
				local tasks_runner = require("nvim-plugins.tasks.tasks")
				tasks_runner.run(e.data, M.state)
			elseif e.type == "launch" then
				local launch_runner = require("nvim-plugins.tasks.launch")
				launch_runner.run(e.data, M.state)
			end
			return
		end
	end

	vim.notify(consts.strings.no_target, vim.log.levels.WARN)
end

---setup plugin
---@param opts Opts
function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	-- namespace
	M.ns = vim.api.nvim_create_namespace(consts.namespace_name)

	-- play icon
	vim.fn.sign_define(consts.sign_name, {
		text = options.sign_icon,
		texthl = options.sign_hl,
	})

	-- attach on read and write
	vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
		pattern = { "*/.vscode/tasks.json", "*/.vscode/launch.json" },
		callback = function(args)
			M.attach(args.buf)
		end,
	})
end

return M
