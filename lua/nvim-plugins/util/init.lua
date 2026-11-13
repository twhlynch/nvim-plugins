local U = {}

-- run shell commands
function U.job_async(cmd, on_success, on_error)
	local stdout_lines = {}
	local stderr_lines = {}

	vim.fn.jobstart(cmd, {
		on_stdout = function(_, data, _)
			for _, line in ipairs(data) do
				table.insert(stdout_lines, line)
			end
		end,
		on_stderr = function(_, data, _)
			for _, line in ipairs(data) do
				table.insert(stderr_lines, line)
			end
		end,
		on_exit = function(_, code, _)
			if code == 0 then
				on_success(table.concat(stdout_lines, "\n"))
			else
				if on_error then
					on_error(table.concat(stderr_lines, "\n") .. " (Exit code: " .. code .. ")")
				end
			end
		end,
		rpc = false,
	})
end

-- from todo-comments.nvim
-- This method returns nil if this buf doesn't have a treesitter parser
--- @param buf integer
--- @param row integer
--- @param col integer
--- @return boolean? true or false otherwise
function U.is_comment(buf, row, col)
	if vim.treesitter.highlighter.active[buf] then
		local captures = vim.treesitter.get_captures_at_pos(buf, row, col)
		for _, c in ipairs(captures) do
			if c.capture == "comment" then
				return true
			end
		end
	else
		local win = vim.fn.bufwinid(buf)
		return win ~= -1 and vim.api.nvim_win_call(win, function()
			for _, i1 in ipairs(vim.fn.synstack(row + 1, col)) do
				local i2 = vim.fn.synIDtrans(i1)
				local n1 = vim.fn.synIDattr(i1, "name")
				local n2 = vim.fn.synIDattr(i2, "name")
				if n1 == "Comment" or n2 == "Comment" then
					return true
				end
			end
		end)
	end
end

return U
