local M = {}

local options = {}

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)
end

function M.is_visual_mode()
	local mode = vim.fn.mode()
	local char = string.sub(mode, 1)
	return char == "v" or char == "V"
end

function M.get_cursor_location()
	local cursor = vim.api.nvim_win_get_cursor(0)
	local cur_row = cursor[1] - 1
	local cur_col = cursor[2]
	local start_row, end_row

	if M.is_visual_mode() then
		start_row = vim.fn.line("'<") - 1
		end_row = vim.fn.line("'>") - 1

		if start_row > end_row then
			start_row, end_row = end_row, start_row
		end
	else
		start_row = cur_row
		end_row = cur_row
	end

	return start_row, end_row, cur_row, cur_col
end

function M.get_inlay_hints(params, callback)
	vim.lsp.buf_request(0, "textDocument/inlayHint", params, function(_, result)
		if not result or vim.tbl_isempty(result) then
			return
		end

		callback(result)
	end)
end

function M.inlay_hints_by_line(hints)
	local lines = {}

	for _, hint in ipairs(hints) do
		local line = hint.position.line

		lines[line] = lines[line] or {}
		table.insert(lines[line], hint)
	end

	return lines
end

function M.inject_line_inlay_hints(lnum, hints)
	table.sort(hints, function(a, b)
		return a.position.character > b.position.character
	end)

	for _, hint in ipairs(hints) do
		M.inject_inlay_hint(hint, lnum, hint.position.character)
	end
end

function M.inject_inlay_hint(hint, row, col)
	local text = type(hint.label) == "table" and table.concat(vim.tbl_map(function(x)
		return x.value
	end, hint.label)) or hint.label

	vim.api.nvim_buf_set_text(0, row, col, row, col, { text })
end

function M.handle_visual_inject(lines)
	for l, hints in pairs(lines) do
		M.inject_line_inlay_hints(l, hints)
	end
end

function M.handle_normal_inject(lines, row, col)
	local hints = lines[row]
	if not hints then
		return
	end

	local best, best_dist
	for _, hint in ipairs(hints) do
		local dist = math.abs(hint.position.character - col)
		if not best or dist < best_dist then
			best = hint
			best_dist = dist
		end
	end

	M.inject_inlay_hint(best, best.position.line, best.position.character)
end

function M.inject_inlay_hints()
	local start_row, end_row, cur_row, cur_col = M.get_cursor_location()

	local params = {
		textDocument = vim.lsp.util.make_text_document_params(),
		range = {
			start = { line = start_row, character = 0 },
			["end"] = { line = end_row, character = 9999 },
		},
	}

	M.get_inlay_hints(params, function(result)
		local lines = M.inlay_hints_by_line(result)

		if M.is_visual_mode() then
			M.handle_visual_inject(lines)
		else
			M.handle_normal_inject(lines, cur_row, cur_col)
		end
	end)
end

return M
