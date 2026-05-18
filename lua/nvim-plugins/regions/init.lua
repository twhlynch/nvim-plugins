local M = {}

--- @class Regions.Options
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

--- @class Regions.Region
---	@field line integer line number
--- @field text string mark text for scrollbar
--- @field type string scrollbar type
--- @field level integer scrollbar level
--- @field priority integer scrollbar priority

--- @type table<integer, Regions.Region[]>
M.regions = {}

-- MARK: internals

--- @param bufnr integer
function M.parse_regions(bufnr)
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

	M.regions[bufnr] = {}

	for i, line in ipairs(lines) do
		for _, pattern in ipairs(options.region_markers) do
			local loc = line:find(pattern, 1, true)

			if loc then
				local text = vim.trim(line:sub(loc + #pattern))

				if text ~= "-" then
					table.insert(M.regions[bufnr], {
						line = i - 1,
						text = text .. "─",
						type = "Info",
						level = 1,
						priority = 1,
					})
				end

				break
			end
		end
	end
end

--- @param bufnr integer
function M.get_regions(bufnr)
	if not M.regions[bufnr] then
		M.parse_regions(bufnr)
	end

	return M.regions[bufnr]
end

--- @param bufnr integer
function M.clear_regions(bufnr)
	M.regions[bufnr] = nil
end

-- MARK: rendering

--- @param bufnr integer
function M.redraw_extmarks(bufnr)
	if not options.divider.enabled then
		return
	end
	vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

	local regions = M.get_regions(bufnr)

	local line_count = vim.api.nvim_buf_line_count(bufnr)

	for _, region in ipairs(regions) do
		local row = region.line
		if row < line_count then
			vim.api.nvim_buf_set_extmark(bufnr, M.ns, row, 0, {
				virt_text = { {
					options.divider.char:rep(999),
					options.divider.hl_group,
				} },
				virt_text_pos = "eol",
			})
		end
	end
end

-- MARK: interaction

--- @param direction 1 | -1
function M.jump_region(direction)
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local regions = M.get_regions(vim.api.nvim_get_current_buf())

	local target

	for i = 1, #regions do
		local r = regions[i]

		if direction == 1 and r.line > line then
			target = r.line
			break
		elseif direction == -1 and r.line < line then
			target = r.line
		end
	end

	if target then
		vim.api.nvim_win_set_cursor(0, { target + 1, 0 })
	end
end

-- MARK: setup

--- @param opts Regions.Options
function M.setup(opts)
	options = vim.tbl_deep_extend("force", options, opts or {})

	-- highlights
	M.ns = vim.api.nvim_create_namespace("RegionDividers")

	vim.api.nvim_set_hl(0, "RegionDivider", {
		link = "Comment",
		default = true,
	})

	-- autocommands
	M.group = vim.api.nvim_create_augroup("RegionsRefresh", { clear = true })

	vim.api.nvim_create_autocmd({
		"BufEnter",
		"TextChanged",
		"TextChangedI",
		"BufWritePost",
	}, {
		group = M.group,
		callback = function(args)
			M.parse_regions(args.buf)
			M.redraw_extmarks(args.buf)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = M.group,
		callback = function(args)
			M.clear_regions(args.buf)
		end,
	})

	-- scrollbar
	require("scrollbar.handlers").register("Regions", function(bufnr)
		return M.get_regions(bufnr)
	end)

	-- jumping
	vim.keymap.set("n", options.keys.next, function()
		M.jump_region(1)
	end)
	vim.keymap.set("n", options.keys.prev, function()
		M.jump_region(-1)
	end)
end

return M
