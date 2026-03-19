local M = {}

local options = {
	dark_color = "#606079",
	light_color = "#e0a363",
	max = 200,
	max_moves = 2000,
	decay_rate = 0.999,
}

local ns = vim.api.nvim_create_namespace("breadcrumbs")

local heat = {}
local gradient = {}

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	M.build_gradient()

	vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
		callback = M.visit,
	})

	vim.api.nvim_create_autocmd({ "BufEnter" }, {
		callback = M.redraw,
	})
end

local ignore = function()
	return --
		not vim.bo.modifiable -- not modifiable
			or vim.bo.readonly -- readonly
			or vim.bo.buftype == "nowrite" -- nowrite
			or vim.bo.buftype == "prompt" -- prompt
			or vim.bo.buftype == "acwrite" -- not a file
end

local function filepath()
	return vim.api.nvim_buf_get_name(0)
end

local function hex_to_rgb(hex)
	hex = hex:gsub("#", "")
	return {
		tonumber(hex:sub(1, 2), 16),
		tonumber(hex:sub(3, 4), 16),
		tonumber(hex:sub(5, 6), 16),
	}
end

local function rgb_to_hex(rgb)
	return string.format("#%02x%02x%02x", rgb[1], rgb[2], rgb[3])
end

local function lerp(a, b, t)
	return a + (b - a) * t
end

function M.build_gradient()
	local dark = hex_to_rgb(options.dark_color)
	local light = hex_to_rgb(options.light_color)

	for i = 0, 256 - 1 do
		local t = i / (256 - 1)

		local rgb = {
			math.floor(lerp(dark[1], light[1], t)),
			math.floor(lerp(dark[2], light[2], t)),
			math.floor(lerp(dark[3], light[3], t)),
		}

		local hex = rgb_to_hex(rgb)
		local hl = "BreadCrumbs_" .. i

		vim.api.nvim_set_hl(0, hl, { fg = hex })

		gradient[i] = hl
	end
end

local function compute_index(value)
	local t = math.min(value / options.max, 1)
	return math.floor(t * (256 - 1))
end

local function total_heat(map)
	local sum = 0
	for _, v in pairs(map) do
		sum = sum + v
	end
	return sum
end

local function decay(map)
	for k, v in pairs(map) do
		map[k] = v * options.decay_rate
	end
end

function M.visit()
	if ignore() then
		return
	end

	local file = filepath()
	if file == "" then
		return
	end

	heat[file] = heat[file] or {}
	local map = heat[file]

	local line = vim.api.nvim_win_get_cursor(0)[1]

	map[line] = (map[line] or 0) + 1

	if total_heat(map) > options.max_moves then
		decay(map)
	end

	local idx = compute_index(map[line])
	if not idx then
		return
	end

	local hl = gradient[idx]

	vim.api.nvim_buf_set_extmark(0, ns, line - 1, 0, {
		number_hl_group = hl,
		priority = 99,
	})
end

function M.redraw()
	if ignore() then
		return
	end

	local file = filepath()
	local map = heat[file]
	if not map then
		return
	end

	local buf = vim.api.nvim_get_current_buf()

	for line, value in pairs(map) do
		local idx = compute_index(value)

		if idx and line <= vim.api.nvim_buf_line_count(0) then
			vim.api.nvim_buf_set_extmark(buf, ns, line - 1, 0, {
				number_hl_group = gradient[idx],
				priority = 99,
			})
		end
	end
end

return M
