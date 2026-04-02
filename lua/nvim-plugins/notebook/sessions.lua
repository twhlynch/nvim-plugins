local M = {}

M.sessions = {}

function M.get_state(bufnr)
	if not M.sessions[bufnr] then
		-- stylua: ignore
		M.sessions[bufnr] = {
			bufnr = bufnr,             -- buffer of notebook
			path = nil,                -- .ipynb file path
			raw_json = { cells = {} }, -- raw json data
			repl_id = nil,             -- repl job id
			parsed_cells = {},         -- parsed cell data
			output_store = {},         -- cell output data
			snacks_images = {},        -- image instances
			read_buffer = "",          -- buffer for reading chunked bridge output
		}
	end

	return M.sessions[bufnr]
end

return M
