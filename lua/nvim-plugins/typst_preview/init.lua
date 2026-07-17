local utils = require("nvim-plugins.typst_preview.utils")

local M = {}

local options = {
	key = "<leader>pt",
	left = "<Left>",
	right = "<Right>",
}

local state = {
	gen = 0, --- @type integer
	buf = nil, --- @type integer | nil
	win = nil, --- @type integer | nil
	src_buf = nil, --- @type integer | nil
	pdf = nil, --- @type string | nil
	page = 1, --- @type integer | nil
	pages = 0, --- @type integer | nil
	cache = {}, --- @type table<integer, string>
	watcher = nil, --- @type uv.uv_fs_event_t | nil
	debounce = nil, --- @type uv.uv_timer_t | nil
	group = nil, --- @type integer | nil
}

--- @param page integer
--- @param win_width integer
local function display(page, win_width)
	if not state.pdf or not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return
	end
	if vim.fn.filereadable(state.pdf) ~= 1 then
		return
	end

	state.pages = utils.count_pages(state.pdf)
	page = math.min(math.max(page, 1), state.pages)
	state.page = page

	local dir = utils.tempdir()
	local cached = state.cache[page]
	local png = cached and vim.fn.filereadable(cached) == 1 and cached or utils.render_page(state.pdf, page, dir, state.gen)
	if not png then
		return
	end
	state.cache[page] = png

	local buf = state.buf
	if not buf or not vim.api.nvim_buf_is_valid(buf) then
		return
	end

	local max_width = win_width and win_width - 1 or nil
	if state.displayed == png and state.max_width == max_width then
		return
	end
	state.displayed = png
	state.max_width = max_width

	utils.attach_image(buf, png, max_width)
end

local function restart_watcher()
	if not state.pdf or not state.win or not vim.api.nvim_win_is_valid(state.win) then
		return
	end
	if state.watcher then
		state.watcher:stop()
	end
	local watcher = vim.uv.new_fs_event()
	if not watcher then
		return
	end
	state.watcher = watcher
	watcher:start(state.pdf, {}, function()
		watcher:stop()
		if state.debounce then
			state.debounce:stop()
		end
		local timer = vim.uv.new_timer()
		if not timer then
			return
		end
		state.debounce = timer
		timer:start(
			300,
			0,
			vim.schedule_wrap(function()
				timer:stop()
				timer:close()
				if state.debounce == timer then
					state.debounce = nil
				end
				if not state.pdf or not state.win or not vim.api.nvim_win_is_valid(state.win) then
					return
				end
				state.gen = state.gen + 1
				state.cache = {}
				state.displayed = nil
				state.max_width = nil
				display(state.page, vim.api.nvim_win_get_width(state.win))
				restart_watcher()
			end)
		)
	end)
end

local function next_page()
	if state.page < state.pages then
		display(state.page + 1, vim.api.nvim_win_get_width(state.win))
	end
end

local function prev_page()
	if state.page > 1 then
		display(state.page - 1, vim.api.nvim_win_get_width(state.win))
	end
end

local cleaning = false
local function cleanup()
	if cleaning then
		return
	end
	cleaning = true
	if state.watcher then
		state.watcher:stop()
		state.watcher = nil
	end
	if state.debounce then
		state.debounce:stop()
		state.debounce = nil
	end
	if state.group then
		pcall(vim.api.nvim_clear_autocmds, { group = state.group })
		state.group = nil
	end
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		pcall(vim.api.nvim_win_close, state.win, true)
	end
	state.buf = nil
	state.win = nil
	state.src_buf = nil
	state.pdf = nil
	state.pages = 0
	state.displayed = nil
	state.max_width = nil
	cleaning = false
end

local function toggle()
	local src = vim.api.nvim_buf_get_name(0)
	if not src:match("%.typ$") then
		return vim.notify("not a typst file", vim.log.levels.WARN)
	end

	local pdf = src:gsub("%.typ$", ".pdf")
	if vim.fn.filereadable(pdf) ~= 1 then
		return vim.notify("pdf not found: " .. pdf, vim.log.levels.WARN)
	end

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		return cleanup()
	end

	cleanup()

	local src_buf = vim.api.nvim_get_current_buf()
	local src_win = vim.api.nvim_get_current_win()
	local width = math.floor(vim.o.columns * 0.40)
	local buf = utils.create_preview_buffer()
	local win = utils.create_preview_window(buf, width)

	state.buf = buf
	state.win = win
	state.src_buf = src_buf
	state.pdf = pdf

	local group = vim.api.nvim_create_augroup("typst_preview", { clear = true })
	state.group = group

	vim.keymap.set("n", options.left, prev_page, { buffer = src_buf, silent = true })
	vim.keymap.set("n", options.right, next_page, { buffer = src_buf, silent = true })

	vim.api.nvim_create_autocmd("WinClosed", {
		group = group,
		pattern = tostring(src_win),
		once = true,
		callback = function()
			vim.schedule(function()
				if state.win then
					cleanup()
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd("WinEnter", {
		group = group,
		callback = function()
			if vim.api.nvim_get_current_win() == win then
				pcall(vim.api.nvim_set_current_win, src_win)
			end
		end,
	})

	vim.api.nvim_create_autocmd("WinResized", {
		group = group,
		callback = function()
			if vim.api.nvim_win_is_valid(win) then
				display(state.page, vim.api.nvim_win_get_width(win))
			end
		end,
	})

	display(state.page, vim.api.nvim_win_get_width(win))
	restart_watcher()
end

--- @param opts table
function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	vim.api.nvim_create_user_command("TypstPreview", toggle, {})
	vim.keymap.set("n", options.key, toggle, { desc = "Typst preview" })
end

return M
