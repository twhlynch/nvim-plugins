local M = {}

local U = require("nvim-plugins.notebook.utils")
local bridge = require("nvim-plugins.notebook.bridge")
local options = require("nvim-plugins.notebook.options")
local rendering = require("nvim-plugins.notebook.rendering")
local sessions = require("nvim-plugins.notebook.sessions")

local api = vim.api

local group = api.nvim_create_augroup("NotebookPlugin", { clear = true })
M.group = group

-- sync all """ and # """ delimiters after a cell change
local function sync_buffer(state, cells)
	local notebook_lines = {}

	for i, cell in ipairs(cells) do
		local src = cell.source

		local delimeter = cell.type == "markdown" and '"""' or ""

		-- borders
		table.insert(notebook_lines, delimeter)
		vim.list_extend(notebook_lines, src)
		table.insert(notebook_lines, delimeter)

		-- code to code
		if cell.type == "code" then
			local next_c = cells[i + 1]
			if next_c and next_c.type == "code" then
				table.insert(notebook_lines, '# """')
			end
		end
	end

	api.nvim_buf_set_lines(state.bufnr, 0, -1, false, notebook_lines)
end

function M.get_current_cell_index(state)
	local cursor_line = api.nvim_win_get_cursor(0)[1] - 1

	-- top line will get above
	if cursor_line == 0 then
		return 0
	end

	-- ensure parsed cells are up to date
	M.parse_buffer(state)

	for i, c in ipairs(state.parsed_cells) do
		if cursor_line >= c.start_line and cursor_line <= (c.end_line + 1) then
			return i
		end
	end

	return nil
end

function M.insert_cell(state, cell_type)
	M.parse_buffer(state)
	local cells = state.parsed_cells
	local current_idx = M.get_current_cell_index(state) or #cells

	-- new blank cell
	local source = cell_type == "code" and options.strings.new_code_cell or options.strings.new_cell
	local new_cell = { type = cell_type, source = source }

	-- insert directly below current
	local insert_idx = current_idx + 1
	table.insert(cells, insert_idx, new_cell)

	-- sync state
	table.insert(state.output_store, insert_idx, {})
	if state.snacks_images then
		table.insert(state.snacks_images, insert_idx, {})
	else
		state.snacks_images = { [insert_idx] = {} }
	end

	-- sync buffer
	sync_buffer(state, cells)
	M.rerender(state)

	-- move cursor into the new cell
	local target_cell = state.parsed_cells[insert_idx]
	if target_cell then
		-- middle for code, start for md
		api.nvim_win_set_cursor(0, { target_cell.start_line + 1 + (cell_type == "code" and 1 or 0), 0 })
	end

	-- insert mode eol
	vim.cmd("startinsert!")
end

function M.remove_cell(state)
	M.parse_buffer(state)
	local cells = state.parsed_cells
	local current_idx = M.get_current_cell_index(state)

	-- first line returns 0
	if current_idx == 0 then
		current_idx = 1
	end

	if not current_idx then
		return
	end

	-- prevent completely clearing the file
	if #cells <= 1 then
		cells[1].source = { "" }
	else
		table.remove(cells, current_idx)
		table.remove(state.output_store, current_idx)
		if state.snacks_images then
			rendering.clear_images(state, current_idx)
			table.remove(state.snacks_images, current_idx)
		end
	end

	-- apply cleanly to buffer
	sync_buffer(state, cells)
	M.rerender(state)

	-- fallback cursor to the cell that took its place, or the new bottom cell
	local target_idx = math.min(current_idx, #state.parsed_cells)
	local target_cell = state.parsed_cells[target_idx]
	if target_cell then
		api.nvim_win_set_cursor(0, { target_cell.start_line + 1, 0 })
	end
end

function M.split_cell(state)
	M.parse_buffer(state)
	local cells = state.parsed_cells

	local idx = M.get_current_cell_index(state)
	-- first line returns 0
	if idx == 0 then
		idx = 1
	end
	if not idx then
		return
	end

	local cell = cells[idx]

	-- cursor position relative to cell
	local cursor_line = api.nvim_win_get_cursor(0)[1] - 1
	local rel = cursor_line - cell.start_line

	-- clamp
	if rel < 0 then
		rel = 0
	end
	if rel > #cell.source then
		rel = #cell.source
	end

	-- split source
	local top = {}
	local bottom = {}

	for i, line in ipairs(cell.source) do
		if i <= rel then
			table.insert(top, line)
		else
			table.insert(bottom, line)
		end
	end

	-- add blank line to empty cells
	if #top == 0 then
		top = { "" }
	end
	if #bottom == 0 then
		bottom = { "" }
	end

	-- replace current cell and insert new one
	cells[idx].source = top

	local new_cell = {
		type = cell.type,
		source = bottom,
	}

	table.insert(cells, idx + 1, new_cell)

	-- sync output
	table.insert(state.output_store, idx + 1, {})
	state.snacks_images = state.snacks_images or {}
	table.insert(state.snacks_images, idx + 1, {})

	-- sync buffer
	sync_buffer(state, cells)
	M.rerender(state)

	-- move cursor to new cell start
	local new_parsed = state.parsed_cells[idx + 1]
	if new_parsed then
		api.nvim_win_set_cursor(0, { new_parsed.start_line + 1, 0 })
	end
end

function M.open_output(state)
	-- get cell containing cursor
	local cell_idx = M.get_current_cell_index(state)

	-- first line returns 0
	if cell_idx == 0 then
		cell_idx = 1
	end

	-- check it has output
	if not cell_idx or not state.output_store[cell_idx] then
		return
	end

	-- collect output text content
	local content = {}

	-- terminal parser to push lines into content
	local parser = U.create_terminal_parser(function(line)
		table.insert(content, line)
	end)

	-- feed outputs into the parser
	for _, out in ipairs(state.output_store[cell_idx]) do
		local text = out.text or (out.data and out.data["text/plain"])
		if text then
			parser.push(text)
		end
	end
	-- flush remaining text
	parser.flush()

	-- check content length
	if #content == 0 then
		return
	end

	-- create floating window
	local fbuf = api.nvim_create_buf(false, true)
	api.nvim_buf_set_lines(fbuf, 0, -1, false, content)

	-- center, 80% max size, content height
	local w = math.floor(vim.o.columns * 0.8)
	local h = math.min(#content + 2, math.floor(vim.o.lines * 0.8))
	local row = (vim.o.lines - h) / 2
	local col = (vim.o.columns - w) / 2

	-- open
	api.nvim_open_win(fbuf, true, {
		relative = "editor",
		width = w,
		height = h,
		row = row,
		col = col,
	})

	-- q or esc to quit
	local opt = { buf = fbuf, silent = true }
	vim.keymap.set("n", "q", "<cmd>close<CR>", opt)
	vim.keymap.set("n", "<ESC>", "<cmd>close<CR>", opt)
end

function M.gx_handler(state)
	-- get cell containing cursor
	local cell_idx = M.get_current_cell_index(state)

	-- first line returns 0
	if cell_idx == 0 then
		cell_idx = 1
	end

	-- check it has output
	if not cell_idx or not state.output_store[cell_idx] then
		vim.cmd("normal! gx")
		return
	end

	local handled = false
	for _, out in ipairs(state.output_store[cell_idx]) do
		-- check for image data
		local img_data = out.data and (out.data["image/png"] or out.data["image/jpeg"])
		if img_data then
			handled = true

			-- clean data
			local clean_data = img_data:gsub("%s+", "")
			local tmp = vim.fn.tempname() .. ".png"

			-- write to temp file
			local ok, decoded = pcall(vim.base64.decode, clean_data)
			if ok then
				local f = io.open(tmp, "wb")
				if f then
					f:write(decoded)
					f:close()
					vim.ui.open(tmp)
				end
			end
		end
	end

	-- fallback to normal gx
	if not handled then
		vim.cmd("normal! gx")
	end
end

function M.clear_output(state)
	-- clear visually
	rendering.clear_ouput(state)

	for i, _ in ipairs(state.parsed_cells) do
		-- clear output
		state.output_store[i] = {}
		-- clear images
		state.snacks_images[i] = {}
	end
end

function M.jump_cell(state, next)
	M.parse_buffer(state)

	local idx = M.get_current_cell_index(state)

	-- first line returns 0
	if idx == 0 then
		idx = 1
	end

	if not idx then
		return
	end

	local target = next and (idx + 1) or (idx - 1)
	local cell = state.parsed_cells[target]
	if not cell then
		return
	end

	api.nvim_win_set_cursor(0, { cell.start_line + 1, 0 })
end

function M.parse_buffer(state)
	-- read lines
	local lines = api.nvim_buf_get_lines(state.bufnr, 0, -1, false)

	-- starting state
	local cells, current_acc, in_md = {}, {}, false
	local start_idx = 0

	-- helper
	local function emit(end_idx)
		local source = U.strip_source(current_acc)
		-- markdown cells and code cells with content
		if in_md or #source > 0 then
			table.insert(cells, {
				type = in_md and "markdown" or "code",
				source = source,
				start_line = start_idx,
				end_line = end_idx,
			})
		end
	end

	-- parse lines
	for i, line in ipairs(lines) do
		if line:match('^"""%s*$') then
			emit(i - 2)
			current_acc, start_idx, in_md = {}, i, not in_md
		elseif line:match('^# """%s*$') and not in_md then
			emit(i - 2)
			current_acc, start_idx, in_md = {}, i, false
		else
			table.insert(current_acc, line)
		end
	end
	emit(#lines - 1)

	-- update state with result
	state.parsed_cells = cells
end

function M.save(state)
	-- get the current cell contents
	M.parse_buffer(state)
	local cells = state.parsed_cells

	local json_cells = {}
	for i, cell in ipairs(cells) do
		local source_lines = U.table_or_str_lines(cell.source)

		-- cell lines ending with newlines
		local formatted_src = {}
		for idx, line in ipairs(source_lines) do
			-- uncomment magics
			local save_line = line
			if cell.type == "code" and line:match("^# %%") then
				save_line = line:gsub("^# ", "")
			end

			local nl = (idx == #source_lines and "" or "\n")
			table.insert(formatted_src, save_line .. nl)
		end

		-- cell outputs with type
		local cell_outputs = state.output_store[i] or {}
		local clean_outputs = {}
		for _, out in ipairs(cell_outputs) do
			if out.output_type then
				table.insert(clean_outputs, out)
			end
		end

		-- append cell info with content
		table.insert(json_cells, {
			cell_type = cell.type,
			metadata = cell.metadata or vim.empty_dict(),
			outputs = clean_outputs,
			source = formatted_src,
		})
	end

	-- update raw cells
	state.raw_json.cells = json_cells

	-- write to source file
	local f = io.open(state.path, "w")
	if f then
		local ok, encoded = pcall(vim.json.encode, state.raw_json)
		if ok then
			local f_ok, formatted = pcall(vim.fn.system, "jq --indent 1 --sort-keys .", encoded)
			if f_ok then
				f:write(formatted)
				f:close()
				vim.bo[state.bufnr].modified = false
			end
		end
	end
end

function M.read_file(state)
	-- decode notebook data with fallback to empty template
	local raw_lines = vim.fn.readfile(state.path)
	local ok, decoded = pcall(vim.json.decode, table.concat(raw_lines, "\n"))
	local blank_notebook = { cells = {}, metadata = vim.empty_dict(), nbformat = 4, nbformat_minor = 5 }
	state.raw_json = ok and decoded or blank_notebook

	-- construct editable notebook content
	local notebook_lines = {}
	for i, cell in ipairs(state.raw_json.cells) do
		-- read cell source content
		local src = U.table_or_str_lines(cell.source)
		local stripped = U.strip_source(src)
		-- comment in empty code cells
		if #stripped == 0 and cell.cell_type == "code" then
			table.insert(stripped, "# empty")
		end

		-- handle magics by commenting them out
		local processed_source = {}
		for _, line in ipairs(stripped) do
			if cell.cell_type == "code" and line:match("^%%") then
				table.insert(processed_source, "# " .. line)
			else
				table.insert(processed_source, line)
			end
		end

		-- surround markdown cells in docstrings and code in newlines
		local delimeter = cell.cell_type == "markdown" and '"""' or ""

		table.insert(notebook_lines, delimeter)
		vim.list_extend(notebook_lines, processed_source)
		table.insert(notebook_lines, delimeter)

		if cell.cell_type == "code" then
			local next_c = state.raw_json.cells[i + 1]
			if next_c and next_c.cell_type == "code" then
				table.insert(notebook_lines, '# """')
			end
		end

		-- read existing cell output
		state.output_store[i] = cell.outputs or {}
		if #state.output_store[i] > 0 then
			state.output_store[i].executed = true
		end
	end

	-- set notebook buffer content
	api.nvim_buf_set_lines(state.bufnr, 0, -1, false, notebook_lines)
	vim.bo[state.bufnr].modified = false
	vim.bo[state.bufnr].filetype = "python"
	vim.bo[state.bufnr].buftype = ""
	vim.bo[state.bufnr].modifiable = true

	-- trick formatters & lsp into thinking this is a real python file
	if vim.api.nvim_buf_get_name(state.bufnr) == "" then
		vim.api.nvim_buf_set_name(state.bufnr, (state.path:gsub("%.ipynb$", ".py")))
	end

	M.rerender(state)
end

function M.run_cells(state, mode)
	-- get cells content
	M.parse_buffer(state)
	local all_cells = state.parsed_cells

	-- get current cell
	local current_idx = M.get_current_cell_index(state)

	if current_idx == 0 then
		current_idx = 1
	end

	if not current_idx and mode ~= "all" then
		return
	end

	-- cells to run based on mode
	local mode_indices = {
		all = vim.fn.range(1, #all_cells),
		up = vim.fn.range(1, current_idx),
		down = vim.fn.range(current_idx, #all_cells),
		current = { current_idx },
	}
	local indices = mode_indices[mode]

	bridge.run_cells(state, indices)
end

function M.rerender(state)
	M.parse_buffer(state)
	rendering.render(state)
end

function M.dump_images(state)
	local choice = vim.fn.confirm(options.strings.images_prompt, "&No\n&Yes", 1)
	if choice ~= 2 then
		return
	end

	local cwd = vim.fn.getcwd()
	local figure_count = 1

	for _, cell_outputs in ipairs(state.output_store or {}) do
		for _, out in ipairs(cell_outputs) do
			local img_data = out.data and (out.data["image/png"] or out.data["image/jpeg"])
			if img_data then
				local ext = out.data["image/png"] and "png" or "jpg"
				local dest_path = string.format("%s/figure_%d.%s", cwd, figure_count, ext)

				-- TODO: move image saving to utils
				local ok, decoded = pcall(vim.base64.decode, img_data:gsub("%s+", ""))
				if ok and decoded then
					local f = io.open(dest_path, "wb")
					if f then
						f:write(decoded)
						f:close()
					end
				end

				figure_count = figure_count + 1
			end
		end
	end

	vim.notify(vim.fn.printf(options.strings.saved_images, figure_count - 1))
end

function M.setup_file(args)
	local bufnr = api.nvim_get_current_buf()
	local state = sessions.get_state(bufnr)

	-- set state file
	state.path = args.file

	-- use hl overrides
	rendering.apply_highlights(vim.api.nvim_get_current_win())

	-- read file content
	M.read_file(state)

	-- keybinds
	local b = { buf = bufnr, silent = true }
	local pref = options.keybind_prefix
	local keys = options.keys

	-- stylua: ignore start
	vim.keymap.set("n", pref .. keys.run_cell,           function() M.run_cells(state, "current") end,    b) -- running
	vim.keymap.set("n", pref .. keys.run_cells_all,      function() M.run_cells(state, "all") end,        b)
	vim.keymap.set("n", pref .. keys.run_cells_up,       function() M.run_cells(state, "up") end,         b)
	vim.keymap.set("n", pref .. keys.run_cells_down,     function() M.run_cells(state, "down") end,       b)
	vim.keymap.set("n", pref .. keys.clear_all_output,   function() M.clear_output(state) end,            b) -- output
	vim.keymap.set("n", pref .. keys.refresh_all_output, function() M.rerender(state) end,                b)
	vim.keymap.set("n",         keys.open_image,         function() M.gx_handler(state) end,              b) -- viewing
	vim.keymap.set("n",         keys.show_output,        function() M.open_output(state) end,             b)
	vim.keymap.set("n",         keys.next_cell,          function() M.jump_cell(state, true) end,         b) -- navigation
	vim.keymap.set("n",         keys.previous_cell,      function() M.jump_cell(state, false) end,        b)
	vim.keymap.set("n", pref .. keys.insert_markdown,    function() M.insert_cell(state, "markdown") end, b) -- editing cells
	vim.keymap.set("n", pref .. keys.insert_code,        function() M.insert_cell(state, "code") end,     b)
	vim.keymap.set("n", pref .. keys.remove_cell,        function() M.remove_cell(state) end,             b)
	vim.keymap.set("n", pref .. keys.split_cell,         function() M.split_cell(state) end,              b)
	vim.keymap.set("n", pref .. keys.dump_images,        function() M.dump_images(state) end,             b) -- utils
	-- stylua: ignore end

	-- override :w with custom save
	api.nvim_create_autocmd({ "BufWriteCmd" }, {
		group = group,
		buffer = bufnr,
		callback = function()
			M.save(state)
		end,
	})

	-- render events
	local last_tick = vim.b.changedtick
	vim.api.nvim_create_autocmd("InsertEnter", {
		group = group,
		buffer = bufnr,
		callback = function()
			last_tick = vim.b.changedtick
		end,
	})
	vim.api.nvim_create_autocmd("InsertLeave", {
		group = group,
		buffer = bufnr,
		callback = function()
			if vim.b.changedtick ~= last_tick then
				M.rerender(state)
			end
		end,
	})
	api.nvim_create_autocmd({ "TextChanged" }, {
		group = group,
		buffer = bufnr,
		callback = function()
			M.rerender(state)
		end,
	})
end

return M
