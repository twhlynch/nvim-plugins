-- based on https://github.com/madmaxieee/nvim-config/blob/c773485d76cf1fff4be3eca888a6ed4525cc9065/lua/plugins/fuzzy-finder/snacks-picker/fff.lua
local M = {}

local staged_status = {
	staged_new = true,
	staged_modified = true,
	staged_deleted = true,
	renamed = true,
}

local status_map = {
	untracked = "untracked",
	modified = "modified",
	deleted = "deleted",
	renamed = "renamed",
	staged_new = "added",
	staged_modified = "modified",
	staged_deleted = "deleted",
	ignored = "ignored",
	unknown = "untracked",
}

---@class FFFState
---@field current_file_cache? string
M.state = {}

local function get_current_file()
	local buf = vim.api.nvim_get_current_buf()
	if buf and vim.api.nvim_buf_is_valid(buf) then
		local name = vim.api.nvim_buf_get_name(buf)
		if name ~= "" and vim.fn.filereadable(name) == 1 then
			return name
		end
	end
	return nil
end

---@type snacks.picker.finder
local function finder(_, ctx)
	local file_picker = require("fff.file_picker")

	if not M.state.current_file_cache then
		M.state.current_file_cache = get_current_file()
	end

	local fff_result = file_picker.search_files(ctx.filter.search or "", M.state.current_file_cache, 100, 4, nil)

	---@type snacks.picker.finder.Item[]
	local items = {}
	for _, fff_item in ipairs(fff_result) do
		local git_status = fff_item.git_status
		items[#items + 1] = {
			text = fff_item.name,
			file = fff_item.path,
			score = fff_item.total_frecency_score,
			status = status_map[git_status] and {
				status = status_map[git_status],
				staged = staged_status[git_status] or false,
				unmerged = git_status == "unmerged",
			} or nil,
		}
	end

	return items
end

local function on_close()
	M.state.current_file_cache = nil
end

local function format_file_git_status(item, picker)
	local ret = {} ---@type snacks.picker.Highlight[]
	local status = item.status
	local hl

	if status.unmerged then
		hl = "SnacksPickerGitStatusUnmerged"
	elseif status.staged then
		hl = "SnacksPickerGitStatusStaged"
	else
		hl = "SnacksPickerGitStatus" .. status.status:sub(1, 1):upper() .. status.status:sub(2)
	end

	local icon = (status.staged and picker.opts.icons.git.staged) or picker.opts.icons.git[status.status] or " "
	local text_icon = status.status == "untracked" and "?" or status.status == "ignored" and "!" or status.status:sub(1, 1):upper()

	ret[#ret + 1] = { icon, hl }
	ret[#ret + 1] = { " ", virtual = true }

	ret[#ret + 1] = {
		col = 0,
		virt_text = { { text_icon, hl }, { " " } },
		virt_text_pos = "right_align",
		hl_mode = "combine",
	}
	return ret
end

local function format(item, picker)
	---@type snacks.picker.Highlight[]
	local ret = {}

	if item.label then
		ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
		ret[#ret + 1] = { " ", virtual = true }
	end

	if item.status then
		vim.list_extend(ret, format_file_git_status(item, picker))
	else
		ret[#ret + 1] = { "  ", virtual = true }
	end

	vim.list_extend(ret, require("snacks.picker.format").filename(item, picker))

	if item.line then
		Snacks.picker.highlight.format(item, item.line, ret)
		table.insert(ret, { " " })
	end
	return ret
end

function M.fff()
	local file_picker = require("fff.file_picker")

	M.state.current_file_cache = get_current_file()

	if not file_picker.is_initialized() then
		local ok = file_picker.setup()
		if not ok then
			vim.notify("fff: failed to initialize file picker", vim.log.levels.ERROR)
			return
		end
	end

	file_picker.search_files("", M.state.current_file_cache, 100, 4, nil)

	Snacks.picker({
		title = "FFFiles",
		finder = finder,
		on_close = on_close,
		format = format,
		live = true,
		on_show = function(picker)
			picker:find()
		end,
	})
end

return M
