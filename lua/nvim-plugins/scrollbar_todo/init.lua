local M = {}

local cache = {}
local changed = true
local last_changedtick = nil

local color_mapping = {
	info = "Info",
	warning = "Warn",
	error = "Error",
	hint = "Hint",
}

local config = require("todo-comments.config")
local highlight = require("todo-comments.highlight")

function M.handler()
	local changedtick = vim.b.changedtick
	if changedtick ~= last_changedtick then
		changed = true
		last_changedtick = changedtick
	end
	if not changed then
		return cache
	end
	changed = false
	local markers = {}

	local opts = config.options or {}
	opts.keywords = opts.keywords or {}

	local buf = vim.api.nvim_get_current_buf()

	for l = 1, vim.api.nvim_buf_line_count(buf) do
		local line = vim.api.nvim_buf_get_lines(buf, l - 1, l, false)[1] or ""
		local ok, start, _, kw = pcall(highlight.match, line)

		if ok and start then
			if opts.highlight.comments_only and highlight.is_comment(buf, l - 1, start) == false then
				kw = nil
			end
		end

		if kw and not opts.keywords[kw] then
			for k, v in pairs(opts.keywords) do
				if vim.tbl_contains(v.alt or {}, kw) then
					kw = k
					break
				end
			end

			if not opts.keywords[kw] then
				kw = nil
			end
		end

		if kw then
			local kw_config = (opts.keywords[kw] or {})
			table.insert(markers, {
				line = l,
				text = vim.trim(kw_config.icon or "!"),
				type = color_mapping[kw_config.color] or "Info",
				level = 4,
			})
		end
	end

	cache = markers
	return markers
end

function M.setup(opts)
	require("scrollbar.handlers").register("TodoCommentLines", M.handler)
end

return M
