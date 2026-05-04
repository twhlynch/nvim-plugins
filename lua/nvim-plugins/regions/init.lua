local M = {}

local options = {
	region_markers = {
		"MARK: ",
		"#region ",
	},
	divider = {
		enabled = true,
		hl_group = "RegionDivider",
		char = "─",
	},
	keys = {
		next = "]r",
		prev = "[r",
	},
}

-- bufnr -> { changedtick, regions[], ns }
M.state = {}

function M.redraw_extmarks(bufnr, regions)
	if not options.divider.enabled then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

	local line_count = vim.api.nvim_buf_line_count(bufnr)

	for _, region in ipairs(regions) do
		local row = region.line
		if row < line_count then
			vim.api.nvim_buf_set_extmark(bufnr, M.ns, row, 0, {
				--- 999 width will be cutoff by the window effectively being the full width
				virt_text = { { options.divider.char:rep(999), options.divider.hl_group } },
				virt_text_pos = "eol",
			})
		end
	end
end

function M.get_regions(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	local changedtick = vim.api.nvim_buf_get_changedtick(bufnr)

	local state = M.state[bufnr]
	if state and state.changedtick == changedtick then
		return state.regions
	end

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local regions = {}

	for i, line in ipairs(lines) do
		local is_region = false
		local mark_text = ""

		for _, pattern in ipairs(options.region_markers) do
			local loc = line:find(pattern, 1, true)
			if loc ~= nil then
				is_region = true
				mark_text = vim.trim(line:sub(loc + #pattern))
				break
			end
		end

		if is_region and mark_text ~= "-" then
			table.insert(regions, {
				line = i - 1,
				text = mark_text .. "─",
				type = "Info",
				level = 1,
				priority = 1,
			})
		end
	end

	M.state[bufnr] = { changedtick = changedtick, regions = regions }

	M.redraw_extmarks(bufnr, regions)

	return regions
end

function M.goto_next_region()
	local bufnr = vim.api.nvim_get_current_buf()
	local regions = M.get_regions(bufnr)
	local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	for _, region in ipairs(regions) do
		if region.line > current_line then
			vim.api.nvim_win_set_cursor(0, { region.line + 1, 0 })
			return
		end
	end
end

function M.goto_prev_region()
	local bufnr = vim.api.nvim_get_current_buf()
	local regions = M.get_regions(bufnr)
	local current_line = vim.api.nvim_win_get_cursor(0)[1] - 1
	for i = #regions, 1, -1 do
		if regions[i].line < current_line then
			vim.api.nvim_win_set_cursor(0, { regions[i].line + 1, 0 })
			return
		end
	end
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	-- hl group
	vim.api.nvim_set_hl(0, "RegionDivider", { link = "Comment", default = true })

	-- scrollbar integration
	require("scrollbar.handlers").register("Regions", function(bufnr)
		return M.get_regions(bufnr)
	end)

	-- namespace
	M.ns = M.ns or vim.api.nvim_create_namespace("RegionDividers")

	-- group
	M.group = M.group or vim.api.nvim_create_augroup("RegionsRefresh", { clear = true })

	-- autocommands
	vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "TextChanged", "InsertLeave" }, {
		group = M.group,
		callback = function(args)
			if M.state[args.buf] then
				M.state[args.buf].changedtick = nil
			end
			M.get_regions(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = M.group,
		callback = function(args)
			M.state[args.buf] = nil
		end,
	})

	-- keys
	vim.keymap.set("n", options.keys.next, M.goto_next_region, { desc = "Next region" })
	vim.keymap.set("n", options.keys.prev, M.goto_prev_region, { desc = "Previous region" })
end

return M
