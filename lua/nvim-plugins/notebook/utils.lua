local M = {}

-- strip empty lines from the beginning and end of a cell
function M.strip_source(source)
	local lines = vim.deepcopy(source)

	if #lines == 0 then
		return lines
	end

	while #lines > 0 and lines[1]:match("^%s*$") do
		table.remove(lines, 1)
	end

	while #lines > 0 and lines[#lines]:match("^%s*$") do
		table.remove(lines)
	end

	if #lines == 0 then
		return { "" }
	end

	return lines
end

-- read lines from a table or string stripping newlines
function M.table_or_str_lines(data, no_nl)
	-- lines in table
	if type(data) == "table" then
		local lines = {}

		for _, line in ipairs(data) do
			local clean = tostring(line):gsub("\r", "")
			if not no_nl then
				-- removing trailing newlines from jupyter will be skipped for stderr
				clean = clean:gsub("\n$", "")
			end
			local split = vim.split(clean, "\n")

			for _, part in ipairs(split) do
				table.insert(lines, part)
			end
		end

		return lines
	end

	-- single line
	local clean = tostring(data or ""):gsub("\r", "")
	local split = vim.split(clean, "\n")

	return split
end

function M.precompiled_ansi_stripper()
	if not M.ansi_stripper then
		local lpeg = vim.lpeg
		local any = lpeg.P(1)
		local ansi_sequence = lpeg.P("\27[") * lpeg.R("09", ";;") ^ 0 * lpeg.R("az", "AZ")
		local stripper = lpeg.Cs((ansi_sequence / "" + any) ^ 0)
		M.ansi_stripper = stripper
	end

	return M.ansi_stripper
end

function M.strip_ansi(str)
	if not str or str == "" then
		return str
	end
	return M.precompiled_ansi_stripper():match(str)
end

function M.create_terminal_parser(on_line_ready)
	local current_line = ""

	return {
		-- process a new chunk of text
		push = function(text)
			if type(text) == "table" then
				text = table.concat(text, "")
			end

			-- simulate \r \b
			local clean_text = M.strip_ansi(text):gsub("\r\n", "\n")
			for i = 1, #clean_text do
				local c = clean_text:sub(i, i)
				if c == "\n" then
					on_line_ready(current_line)
					current_line = ""
				elseif c == "\r" then
					current_line = ""
				elseif c == "\b" then
					if #current_line > 0 then
						current_line = current_line:sub(1, -2)
					end
				else
					current_line = current_line .. c
				end
			end
		end,

		-- force output of any remaining text in the buffer
		flush = function()
			if current_line ~= "" then
				on_line_ready(current_line)
				current_line = ""
			end
		end,
	}
end

---@diagnostic disable-next-line: undefined-field
local render_timer = vim.loop.new_timer()
function M.debounce(func)
	render_timer:stop()
	render_timer:start(50, 0, vim.schedule_wrap(func))
end

return M
