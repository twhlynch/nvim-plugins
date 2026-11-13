local Scan = require("nvim-plugins.util.scan")
local util = require("nvim-plugins.util")

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

--- @type table<integer, Regions.Region[]>
M.regions = {}

-- MARK: internals

local scanners = {}
local drawn = {}
local versions = {}
local divider_str = ""

--- @param bufnr integer
local function make_scanner(bufnr)
	return Scan.new(bufnr, {
		needles = function()
			return options.region_markers
		end,
		match = function(line, lnum)
			for _, pattern in ipairs(options.region_markers) do
				local loc = line:find(pattern, 1, true)

				if loc then
					-- FIXME: not working
					-- if util.is_comment(bufnr, lnum - 1, loc - 1) == false then
					-- 	return nil
					-- end

					local text = vim.trim(line:sub(loc + #pattern))

					if text ~= "-" then
						return {
							text = text .. "─",
							type = "Info",
						}
					end

					return nil
				end
			end

			return nil
		end,
	})
end

--- @param bufnr integer
function M.get_scanner(bufnr)
	local scanner = scanners[bufnr]

	if not scanner or scanner.detached then
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return nil
		end

		scanner = make_scanner(bufnr)
		scanners[bufnr] = scanner
		M.regions[bufnr] = nil
		versions[bufnr] = nil
	end

	return scanner
end

--- @param entries { line: integer, value: table }[]
local function to_list(entries)
	local list = {}

	for _, entry in ipairs(entries) do
		local value = entry.value
		list[#list + 1] = {
			line = entry.line - 1,
			text = value.text,
			type = value.type,
		}
	end

	return list
end

--- @param bufnr integer
function M.get_regions(bufnr)
	local scanner = M.get_scanner(bufnr)
	if not scanner then
		return {}
	end

	-- rescan dirty lines
	scanner:update()

	local cached = M.regions[bufnr]
	if cached and versions[bufnr] == scanner.version then
		return cached
	end

	local list = to_list(scanner:entries())
	M.regions[bufnr] = list
	versions[bufnr] = scanner.version
	return list
end

--- @param bufnr integer
function M.parse_regions(bufnr)
	local scanner = M.get_scanner(bufnr)
	if not scanner then
		return
	end

	scanner:invalidate()
	scanner:update()
	M.get_regions(bufnr)
end

--- @param bufnr integer
function M.clear_regions(bufnr)
	local scanner = scanners[bufnr]
	if scanner then
		scanner:destroy()
	end

	scanners[bufnr] = nil
	M.regions[bufnr] = nil
	versions[bufnr] = nil
	drawn[bufnr] = nil
end

-- MARK: rendering

--- @param bufnr integer
function M.redraw_extmarks(bufnr)
	if not options.divider.enabled then
		return
	end

	local scanner = M.get_scanner(bufnr)
	if not scanner then
		return
	end

	local regions = M.get_regions(bufnr)

	-- extmarks persist in the buffer, only redraw when regions actually changed
	if drawn[bufnr] == scanner.version then
		return
	end

	vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)

	local line_count = vim.api.nvim_buf_line_count(bufnr)

	for _, region in ipairs(regions) do
		local row = region.line
		if row < line_count then
			vim.api.nvim_buf_set_extmark(bufnr, M.ns, row, 0, {
				virt_text = { {
					divider_str,
					options.divider.hl_group,
				} },
				virt_text_pos = "eol",
			})
		end
	end

	drawn[bufnr] = scanner.version
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
	divider_str = options.divider.char:rep(999)

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
	require("scrollbar.providers").register({
		name = "Regions",
		refresh_owner = { buffer = "provider" },
		setup = function(context)
			local group = context.create_augroup("RegionsUpdates")
			vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "TextChangedP", "BufWinEnter", "WinEnter" }, {
				group = group,
				callback = function(args)
					local bufnr = args.buf ~= 0 and args.buf or vim.api.nvim_get_current_buf()
					if context.is_buffer_eligible(bufnr) then
						context.set_marks(bufnr, M.get_regions(bufnr))
					else
						context.clear_marks(bufnr)
					end
				end,
			})
		end,
		refresh = function(bufnr)
			return M.get_regions(bufnr)
		end,
	})

	-- jumping
	vim.keymap.set("n", options.keys.next, function()
		M.jump_region(1)
	end)
	vim.keymap.set("n", options.keys.prev, function()
		M.jump_region(-1)
	end)
end

return M
