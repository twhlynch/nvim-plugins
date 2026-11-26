local M = {}

local options = {
	keymap = "<leader><Tab>",
	filepath = "~/TODO.md",
}

M.todo_win = nil

function M.close_todo()
	if not M.todo_win or not vim.api.nvim_win_is_valid(M.todo_win) then
		M.todo_win = nil
		return
	end

	local buf = vim.api.nvim_win_get_buf(M.todo_win)

	vim.api.nvim_buf_call(buf, function()
		vim.cmd("silent noautocmd write")
	end)

	vim.api.nvim_win_close(M.todo_win, true)
	M.todo_win = nil
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	vim.keymap.set("n", options.keymap, function()
		if M.todo_win and vim.api.nvim_win_is_valid(M.todo_win) then
			M.close_todo()
			return
		end

		local path = vim.fn.expand(options.filepath)
		local buf = vim.fn.bufadd(path)
		vim.fn.bufload(buf)

		local width = math.min(50, vim.o.columns - 4)
		local height = math.min(15, vim.o.lines - 4)

		M.todo_win = vim.api.nvim_open_win(buf, true, {
			relative = "editor",
			width = width,
			height = height,
			col = vim.o.columns - width - 3,
			row = 1,
			title = " TODO ",
			title_pos = "center",
		})

		vim.wo[M.todo_win].wrap = true
		vim.bo[buf].bufhidden = "wipe"
		vim.b[buf].disable_autoformat = true

		vim.keymap.set("n", "q", M.close_todo, {
			buffer = buf,
			silent = true,
			nowait = true,
		})
	end, { desc = "Toggle TODO list" })
end

return M
