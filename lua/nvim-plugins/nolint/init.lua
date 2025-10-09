local M = {}

local options = {
	key = "gcs",
}

function M.flag_from_diagnostic(diagnostic)
	local flag = diagnostic.code or diagnostic.message:match("%[(.-)%]") or nil
	if flag == nil or flag:sub(1, 1) == "-" then
		return nil
	end
	return flag
end

function M.insert_silence_at_line(bufnr, line, flag)
	local silence_text = " // NOLINT"
	if flag ~= nil then
		silence_text = silence_text .. "(" .. flag .. ")"
	end

	local current_line = vim.api.nvim_buf_get_lines(bufnr, line, line + 1, false)[1]
	if current_line ~= nil then
		local current_line_len = #current_line
		vim.api.nvim_buf_set_text(bufnr, line, current_line_len, line, current_line_len, { silence_text })
	end
end

-- normal
function M.insert_ignore_clang_warning()
	local bufnr = vim.api.nvim_get_current_buf()
	local line = vim.api.nvim_win_get_cursor(0)[1] - 1
	local diagnostics = vim.diagnostic.get(bufnr)

	for _, diagnostic in ipairs(diagnostics) do
		if line == diagnostic.lnum then
			local flag = M.flag_from_diagnostic(diagnostic)
			M.insert_silence_at_line(bufnr, diagnostic.lnum, flag)
		end
	end
end
-- visual
function M.insert_ignore_clang_warnings()
	local bufnr = vim.api.nvim_get_current_buf()
	-- wtf is the right way to get visual selection position this sucks
	local vstart = vim.fn.getpos("v")[1] - 1
	local vend = vim.api.nvim_win_get_cursor(0)[1] - 1
	if vstart > vend then
		local temp = vstart
		vstart = vend
		vend = temp
	end
	local diagnostics = vim.diagnostic.get(bufnr)

	for _, diagnostic in ipairs(diagnostics) do
		if vstart <= diagnostic.lnum and diagnostic.lnum <= vend then
			local flag = M.flag_from_diagnostic(diagnostic)
			M.insert_silence_at_line(bufnr, diagnostic.lnum, flag)
		end
	end
end

---@diagnostic disable-next-line: unused-local
function M.attach(client, bufnr)
	vim.keymap.set("n", options.key, M.insert_ignore_clang_warning, { buffer = bufnr, desc = "Insert diagnostic silence comments" })
	vim.keymap.set("x", options.key, M.insert_ignore_clang_warnings, { buffer = bufnr, desc = "Insert diagnostic silence comments" })
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	local augroup = vim.api.nvim_create_augroup("ClangdIgnoreWarnings", { clear = true })

	vim.api.nvim_create_autocmd("LspAttach", {
		group = augroup,
		callback = function(e)
			local bufnr = e.buf
			local client = vim.lsp.get_client_by_id(e.data.client_id)
			if client and client.name == "clangd" then
				M.attach(client, bufnr)
			end
		end,
	})
end

return M
