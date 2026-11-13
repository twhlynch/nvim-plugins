local Scan = require("nvim-plugins.util.scan")
local util = require("nvim-plugins.util")

local M = {}

local scanners = {}

local color_mapping = {
	info = "Info",
	warning = "Warn",
	error = "Error",
	hint = "Hint",
}

local config = require("todo-comments.config")
local highlight = require("todo-comments.highlight")

local function make_scanner(bufnr)
	return Scan.new(bufnr, {
		-- quick check just uses the keywords list
		needles = function()
			return vim.tbl_keys(config.keywords or {})
		end,
		-- main check
		match = function(line, lnum)
			local opts = config.options or {}
			local keywords = opts.keywords or {}

			-- match line
			local ok, start, _, kw = pcall(highlight.match, line)
			if not ok or not start then
				return nil
			end

			-- check comment
			local highlight_opts = opts.highlight or {}
			if highlight_opts.comments_only and util.is_comment(bufnr, lnum - 1, start) == false then
				kw = nil
			end

			-- check keyword
			if kw and not keywords[kw] then
				for k, v in pairs(keywords) do
					local alt = type(v) == "table" and v.alt or nil
					if alt and vim.tbl_contains(alt, kw) then
						kw = k
						break
					end
				end

				if not keywords[kw] then
					kw = nil
				end
			end

			if not kw then
				return nil
			end

			-- return marks
			local kw_config = type(keywords[kw]) == "table" and keywords[kw] or {}
			return {
				text = vim.trim(kw_config.icon or "!"),
				type = color_mapping[kw_config.color] or "Info",
				level = 4,
			}
		end,
	})
end

local function get_scanner(bufnr)
	local scanner = scanners[bufnr]

	if not scanner or scanner.detached then
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return nil
		end

		scanner = make_scanner(bufnr)
		scanners[bufnr] = scanner
	end

	return scanner
end

function M.handler(buf)
	local scanner = get_scanner(buf)
	if not scanner then
		return {}
	end

	local entries = scanner:all()

	local markers = {}
	for _, entry in ipairs(entries) do
		local value = entry.value
		markers[#markers + 1] = {
			line = entry.line,
			text = value.text,
			type = value.type,
		}
	end

	return markers
end

function M.setup(opts)
	require("scrollbar.providers").register({
		name = "TodoCommentLines",
		refresh_owner = { buffer = "provider" },
		setup = function(context)
			local group = context.create_augroup("TodoCommentLinesUpdates")
			vim.api.nvim_create_autocmd({ "BufEnter", "TextChanged", "TextChangedI", "TextChangedP", "BufWinEnter", "WinEnter" }, {
				group = group,
				callback = function(args)
					local bufnr = args.buf ~= 0 and args.buf or vim.api.nvim_get_current_buf()
					if context.is_buffer_eligible(bufnr) then
						context.set_marks(bufnr, M.handler(bufnr))
					else
						context.clear_marks(bufnr)
					end
				end,
			})
		end,
		refresh = M.handler,
	})

	local group = vim.api.nvim_create_augroup("ScrollbarTodoRefresh", { clear = true })

	vim.api.nvim_create_autocmd("BufWipeout", {
		group = group,
		callback = function(args)
			local scanner = scanners[args.buf]
			if scanner then
				scanner:destroy()
				scanners[args.buf] = nil
			end
		end,
	})
end

return M
