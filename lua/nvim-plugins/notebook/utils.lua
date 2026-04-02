local M = {}

-- strip empty lines from the beginning and end of a cell
function M.strip_source(source)
	local lines = vim.deepcopy(source)

	while #lines > 0 and lines[1]:match("^%s*$") do
		table.remove(lines, 1)
	end

	while #lines > 0 and lines[#lines]:match("^%s*$") do
		table.remove(lines)
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

return M
