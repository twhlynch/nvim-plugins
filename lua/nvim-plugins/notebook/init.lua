local M = {}

-- stylua: ignore
local options = {
	keybind_prefix = "<leader>c",
	max_output_lines = 10,
	custom_plot_theme = true,
	custom_theme_colors = { '#4878CF', '#6ACC65', '#D65F5F', '#B47CC7', '#C4AD66', '#77BEDB' },

	hl = {
		output  = "NonText",
		error   = "DiagnosticError",
		hint    = "DiagnosticHint",
		success = "DiagnosticOk",
	},

	strings = {
		output_border    = "┃   ",
		cell_border      = "─",
		cell_executed    = "[ ✓ Done ]",
		truncated_output = "<Enter> %s more lines",
		image_output     = "<gx> %s × image",

		bridge_error    = "Jupyter Bridge Error: ",
		install_prompt  = "Missing 'jupyter_client'. Install with pip?",
		no_client       = "Not running client",
		installing      = "Installing jupyter_client...",
		install_success = "Successfully installed",
		install_fail    = "Failed to install",
	},
}

local api = vim.api

local group = api.nvim_create_augroup("NotebookPlugin", { clear = true })
local ex_ns = api.nvim_create_namespace("nb_extmarks")
local hl_ns = api.nvim_create_namespace("nb_highlights")

-- state management

M.sessions = {}

function M.get_state(bufnr)
	bufnr = bufnr or api.nvim_get_current_buf()
	if not M.sessions[bufnr] then
		M.sessions[bufnr] = {
			path = nil,
			raw_json = { cells = {} },
			repl_id = nil,
			parsed_cells = {},
			output_store = {},
			snacks_images = {},
		}
	end
	return M.sessions[bufnr]
end

-- helpers

local function strip_source(source)
	local lines = vim.deepcopy(source)

	while #lines > 0 and lines[1]:match("^%s*$") do
		table.remove(lines, 1)
	end

	while #lines > 0 and lines[#lines]:match("^%s*$") do
		table.remove(lines)
	end

	return lines
end

local function strip_ansi(str)
	return string.gsub(str, "\27%[[0-9;]*[a-zA-Z]", "")
end

local function table_or_str_lines(data, no_nl)
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

-- rendering

local function insert_virtual_line(tble, type, text)
	local border = options.strings.output_border
	text = tostring(text) or ""
	-- stylua: ignore
	local line_table = {
		success    = { { border, options.hl.output }, { options.strings.cell_executed,                         options.hl.success } },
		output     = { { border, options.hl.output }, { text,                                                  options.hl.output  } },
		error      = { { border, options.hl.error  }, { text,                                                  options.hl.error   } },
		truncation = { { border, options.hl.output }, { string.format(options.strings.truncated_output, text), options.hl.hint    } },
		image      = { { border, options.hl.output }, { string.format(options.strings.image_output, text),     options.hl.hint    } },
	}

	table.insert(tble, line_table[type])
end

local function insert_separator(bufnr, line)
	local width = api.nvim_win_get_width(0)
	local virt_text = string.rep(options.strings.cell_border, width)

	api.nvim_buf_set_extmark(bufnr, ex_ns, line, 0, {
		virt_text = { { virt_text, options.hl.output } },
		virt_text_pos = "overlay",
		priority = 1,
	})
end

function M.render_cell(i)
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)
	local cell = state.parsed_cells[i]

	if not cell then
		return
	end

	-- borders over """
	if cell.type == "markdown" then
		insert_separator(bufnr, cell.start_line - 1)
		insert_separator(bufnr, cell.end_line + 1)
	end

	-- everything else is just for code
	if cell.type ~= "code" then
		return
	end

	-- get code output
	local cell_out = state.output_store[i] or {}
	local virt_lines = {}
	local count = 0
	local img_count = 0

	-- show success if it was executed
	if cell_out.executed then
		insert_virtual_line(virt_lines, "success")
	end

	-- cleanup existing snacks images
	if state.snacks_images[i] then
		for _, img in ipairs(state.snacks_images[i]) do
			img:close()
		end
		state.snacks_images[i] = {}
	end

	local has_snacks, snacks = pcall(require, "snacks")
	state.snacks_images[i] = state.snacks_images[i] or {}
	local snacks_images = {}
	local image_position = { cell.end_line + 1, 0 }

	for _, out in ipairs(cell_out) do
		-- process images
		local img_data = out.data and (out.data["image/png"] or out.data["image/jpeg"])
		if img_data then
			img_count = img_count + 1

			if has_snacks then
				local clean_data = img_data:gsub("%s+", "")
				local decoded = vim.base64.decode(clean_data)

				-- save to a temp file
				local tmp = vim.fn.tempname() .. "_" .. i .. "_" .. img_count .. ".png"
				local f = io.open(tmp, "wb")
				if f then
					f:write(decoded)
					f:close()
					-- save image info
					table.insert(snacks_images, {
						src = tmp,
						opts = {
							pos = image_position,
							max_width = 50,
							max_height = 20,
							inline = true,
						},
					})
				end
			end
		end

		-- render text output
		local text = out.text or (out.data and out.data["text/plain"])
		if text then
			local lines = table_or_str_lines(text)
			for _, line in ipairs(lines) do
				count = count + 1
				-- truncate
				if count <= options.max_output_lines then
					insert_virtual_line(virt_lines, "output", line)
				end
			end
		end

		-- render errors
		if out.output_type == "error" or out.traceback then
			local lines = table_or_str_lines(out.traceback, true)
			for _, line in ipairs(lines) do
				local clean = strip_ansi(line)
				insert_virtual_line(virt_lines, "error", clean)
			end
		end
	end

	-- truncation
	if count > options.max_output_lines then
		cell_out.is_truncated = true
		insert_virtual_line(virt_lines, "truncation", (count - options.max_output_lines))
	else
		cell_out.is_truncated = false
	end

	-- images virtual text
	if img_count > 0 then
		insert_virtual_line(virt_lines, "image", img_count)
	end

	-- add images first and in reverse to show last
	for j = #snacks_images, 1, -1 do
		local image = snacks_images[j]
		local img_obj = snacks.image.placement.new(bufnr, image.src, image.opts)
		table.insert(state.snacks_images[i], img_obj)
	end

	-- add border for any output or images
	if #virt_lines > 0 or #snacks_images > 0 then
		local width = api.nvim_win_get_width(0)
		local border = string.rep(options.strings.cell_border, width)
		-- prepend to start
		table.insert(virt_lines, 1, { { border, options.hl.output } })
	end

	-- add extmarks to buffer
	if #virt_lines > 0 then
		pcall(api.nvim_buf_set_extmark, bufnr, ex_ns, cell.end_line, 0, { virt_lines = virt_lines })
	end
end

function M.render(bufnr)
	bufnr = bufnr or api.nvim_get_current_buf()
	local state = M.get_state(bufnr)

	-- clear extmarks
	api.nvim_buf_clear_namespace(bufnr, ex_ns, 0, -1)

	-- update parsed cell content
	M.parse_buffer(bufnr)

	-- render each cell
	for i, _ in ipairs(state.parsed_cells) do
		M.render_cell(i)
	end
end

-- running cells

function M.stdout_callback(bufnr, data)
	if not data then
		return
	end

	local state = M.get_state(bufnr)

	for _, line in ipairs(data) do
		if line ~= "" then
			local ok, msg = pcall(vim.json.decode, line)
			if ok and msg.cell_idx then
				local idx = msg.cell_idx
				state.output_store[idx] = state.output_store[idx] or {}

				if msg.type == "stream" then
					table.insert(state.output_store[idx], {
						output_type = "stream",
						text = msg.content.text,
					})
				elseif msg.type == "display_data" or msg.type == "execute_result" then
					table.insert(state.output_store[idx], {
						output_type = msg.type,
						data = msg.content.data,
					})
				elseif msg.type == "error" then
					table.insert(state.output_store[idx], {
						output_type = "error",
						traceback = msg.content.traceback,
					})
				elseif msg.type == "status" and msg.content.execution_state == "idle" then
					state.output_store[idx].executed = true
				end
			end

			-- output counts as a file change
			vim.bo[bufnr].modified = true
		end
	end

	vim.schedule(function()
		M.render(bufnr)
	end)
end

function M.stderr_callback(_, data)
	if not data or #data == 0 or data[1] == "" then
		return
	end
	vim.schedule(function()
		vim.notify(options.strings.bridge_error .. table.concat(data, "\n"), vim.log.levels.ERROR)
	end)
end

function M.prompt_install(python)
	local choice = vim.fn.confirm(options.strings.install_prompt, "&Yes\n&No", 1)

	if choice == 0 then
		vim.notify(options.strings.no_client, vim.log.levels.WARN)
		return
	end

	vim.notify(options.strings.installing, vim.log.levels.INFO)
	local install_cmd = { python, "-m", "pip", "install", "jupyter_client", "ipykernel" }
	vim.fn.jobstart(install_cmd, {
		on_exit = function(_, code)
			if code == 0 then
				vim.notify(options.strings.install_success, vim.log.levels.INFO)
			else
				vim.notify(options.strings.install_fail, vim.log.levels.ERROR)
			end
		end,
	})
end

function M.start_repl(bufnr)
	local state = M.get_state(bufnr)

	-- find ideal python executable
	local cmd = "python3"
	local local_venv = vim.fn.getcwd() .. "/.venv/bin/python3"
	if vim.fn.executable(local_venv) == 1 then
		cmd = local_venv
	else
		local parent_venv = vim.fn.getcwd() .. "/../.venv/bin/python3"
		if vim.fn.executable(parent_venv) == 1 then
			cmd = parent_venv
		end
	end

	-- autoinstall jupyter_client
	vim.fn.system({ cmd, "-c", "import jupyter_client" })
	if vim.v.shell_error ~= 0 then
		M.prompt_install(cmd)
		return false
	end

	-- python bridge using jupyter_client
	local BRIDGE_PY = [[
import sys, json
from jupyter_client import KernelManager

def main():
    try:
        km = KernelManager(kernel_name='python3')
        km.start_kernel()
        kc = km.client()
        kc.start_channels()
        kc.wait_for_ready()
]] .. (options.custom_plot_theme and [[
        setup_code = """
try:
    import matplotlib.pyplot as plt
    from cycler import cycler

    plt.rcParams['axes.prop_cycle'] = cycler('color', [']] .. table.concat(options.custom_theme_colors, "', '") .. [['])

    white    = (0.9, 0.9, 0.9, 1)
    black    = (0, 0, 0, 1)
    ts       = (0, 0, 0, 0)
    ts_white = (0.9, 0.9, 0.9, 0.05)
    ts_black = (0, 0, 0, 0.1)

    plt.rcParams['lines.color'] = white
    plt.rcParams['patch.edgecolor'] = white
    plt.rcParams['text.color'] = white

    plt.rcParams['axes.facecolor'] = ts
    plt.rcParams['axes.edgecolor'] = white
    plt.rcParams['axes.labelcolor'] = white

    plt.rcParams['xtick.color'] = white
    plt.rcParams['ytick.color'] = white

    plt.rcParams['grid.color'] = white

    plt.rcParams['figure.facecolor'] = ts
    plt.rcParams['figure.edgecolor'] = black

    plt.rcParams['boxplot.boxprops.color'] = white
    plt.rcParams['boxplot.capprops.color'] = white
    plt.rcParams['boxplot.flierprops.color'] = white
    plt.rcParams['boxplot.flierprops.markeredgecolor'] = white
    plt.rcParams['boxplot.whiskerprops.color'] = white

except:
    pass
"""
        kc.execute(setup_code, silent=True)
]] or "") .. [[
        for line in sys.stdin:
            if not line.strip(): continue
            req = json.loads(line)
            cell_idx = req["cell_idx"]
            msg_id = kc.execute(req["code"])

            while True:
                msg = kc.get_iopub_msg()
                msg_type = msg['header']['msg_type']
                content = msg['content']
                parent_id = msg['parent_header'].get('msg_id')

                if parent_id == msg_id:
                    out = {"cell_idx": cell_idx, "type": msg_type, "content": content}
                    sys.stdout.write(json.dumps(out) + "\n")
                    sys.stdout.flush()

                    if msg_type == 'status' and content.get('execution_state') == 'idle':
                        break
    except Exception as e:
        sys.stderr.write(f"Bridge Error: {str(e)}\n")
        sys.stderr.flush()

if __name__ == '__main__':
    main()
]]

	-- start repl executing bridge script
	local command = { cmd, "-c", BRIDGE_PY }

	-- start repl
	state.repl_id = vim.fn.jobstart(command, {
		on_stdout = function(_, data)
			M.stdout_callback(bufnr, data)
		end,
		on_stderr = function(_, data)
			M.stderr_callback(bufnr, data)
		end,
	})

	return true
end

function M.run_cells(mode)
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)

	-- get cells content
	local all_cells = M.parse_buffer(bufnr)

	-- get current cell
	local current_idx = M.get_current_cell_index()
	if not current_idx and mode ~= "all" then
		return
	end

	-- start repl if needed
	if not state.repl_id or vim.fn.jobwait({ state.repl_id }, 0)[1] ~= -1 then
		-- If start_repl fails abort execution
		if not M.start_repl(bufnr) then
			return
		end
	end

	-- cells to run based on mode
	local mode_indices = {
		all = vim.fn.range(1, #all_cells),
		above = vim.fn.range(1, current_idx),
		current = { current_idx },
	}
	local indices = mode_indices[mode]

	-- run required cells in order
	for _, i in ipairs(indices) do
		-- if cell is code
		if all_cells[i].type == "code" then
			-- get code lines
			local code = table.concat(all_cells[i].source, "\n")
			if code ~= "" then
				-- reset executed state
				state.output_store[i] = { executed = false }

				-- send execution request as json
				local req = vim.json.encode({ cell_idx = i, code = code })
				vim.fn.chansend(state.repl_id, req .. "\n")
			end
		end
	end
end

-- ui actions

function M.get_current_cell_index()
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)
	local cursor_line = api.nvim_win_get_cursor(0)[1] - 1

	-- ensure parsed cells are up to date
	M.parse_buffer(bufnr)

	for i, c in ipairs(state.parsed_cells) do
		if cursor_line >= c.start_line and cursor_line <= (c.end_line + 1) then
			return i
		end
	end

	return nil
end

function M.open_output_float()
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)

	-- get cell containing cursor
	local cell_idx = M.get_current_cell_index()

	-- check it has output
	if not cell_idx or not state.output_store[cell_idx] then
		return
	end

	-- collect output text content
	local content = {}
	for _, out in ipairs(state.output_store[cell_idx]) do
		local text = out.text or (out.data and out.data["text/plain"])
		if text then
			local lines = table_or_str_lines(text)
			for _, line in ipairs(lines) do
				table.insert(content, line)
			end
		end
	end

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
	local opt = { buffer = fbuf, silent = true }
	vim.keymap.set("n", "q", "<cmd>close<CR>", opt)
	vim.keymap.set("n", "<ESC>", "<cmd>close<CR>", opt)
end

function M.gx_handler()
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)

	-- get cell containing cursor
	local cell_idx = M.get_current_cell_index()

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

function M.clear_output()
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)

	-- clear extmarks
	api.nvim_buf_clear_namespace(bufnr, ex_ns, 0, -1)

	for i, _ in ipairs(state.output_store) do
		local cell = state.parsed_cells[i]

		-- clear output
		state.output_store[i] = {}

		-- clear images
		if state.snacks_images[i] then
			for _, img in ipairs(state.snacks_images[i]) do
				img:close()
			end
			state.snacks_images[i] = {}
		end

		-- borders over """
		if cell.type == "markdown" then
			insert_separator(bufnr, cell.start_line - 1)
			insert_separator(bufnr, cell.end_line + 1)
		end
	end
end

-- main file content handling

function M.parse_buffer(bufnr)
	local state = M.get_state(bufnr)

	-- read lines
	local lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)

	-- starting state
	local cells, current_acc, in_md = {}, {}, false
	local start_idx = 0

	-- helper
	local function emit(end_idx)
		local source = strip_source(current_acc)
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
		else
			table.insert(current_acc, line)
		end
	end
	emit(#lines - 1)

	-- update state with result
	state.parsed_cells = cells
	return cells
end

function M.save()
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)

	-- get the current cell contents
	local cells = M.parse_buffer(bufnr)

	local json_cells = {}
	for i, cell in ipairs(cells) do
		local source_lines = table_or_str_lines(cell.source)

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
			metadata = cell.metadata or {},
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
			f:write(encoded)
			f:close()
			vim.bo[bufnr].modified = false
		end
	end
end

function M.read_file(state)
	local bufnr = api.nvim_get_current_buf()

	-- decode notebook data with fallback to empty template
	local raw_lines = vim.fn.readfile(state.path)
	local ok, decoded = pcall(vim.json.decode, table.concat(raw_lines, "\n"))
	local blank_notebook = { cells = {}, metadata = {}, nbformat = 4, nbformat_minor = 5 }
	state.raw_json = ok and decoded or blank_notebook

	-- construct editable notebook content
	local notebook_lines = {}
	for i, cell in ipairs(state.raw_json.cells) do
		-- read cell source content
		local src = table_or_str_lines(cell.source)
		local stripped = strip_source(src)
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
		for _, l in ipairs(processed_source) do
			table.insert(notebook_lines, l)
		end
		table.insert(notebook_lines, delimeter)

		-- read existing cell output
		state.output_store[i] = cell.outputs or {}
		if #state.output_store[i] > 0 then
			state.output_store[i].executed = true
		end
	end

	-- set notebook buffer content
	api.nvim_buf_set_lines(bufnr, 0, -1, false, notebook_lines)
	vim.bo[bufnr].modified = false
	vim.bo[bufnr].filetype = "python"

	M.render(bufnr)
end

function M.setup_file(args)
	local bufnr = api.nvim_get_current_buf()
	local state = M.get_state(bufnr)
	state.path = args.file

	-- replace python docstrings with markdown
	-- stylua: ignore
	vim.treesitter.query.set("python", "injections", [[
		((expression_statement
		   (string
		     (string_content) @injection.content) @docstring)
		 (#set! injection.language "markdown")
		 (#set! injection.combined))
	]])

	-- use hl overrides
	api.nvim_win_set_hl_ns(0, hl_ns)

	M.read_file(state)

	-- keybinds
	local b = { buffer = bufnr, silent = true }
	-- stylua: ignore start
	vim.keymap.set("n", options.keybind_prefix .. "a",    function() M.run_cells("all") end,     b)
	vim.keymap.set("n", options.keybind_prefix .. "r",    function() M.run_cells("current") end, b)
	vim.keymap.set("n", options.keybind_prefix .. "x",    M.clear_output,                        b)
	vim.keymap.set("n",                           "gx",   M.gx_handler,                          b)
	vim.keymap.set("n",                           "<CR>", M.open_output_float,                   b)
	-- stylua: ignore end

	-- override :w with custom save
	api.nvim_create_autocmd({ "BufWriteCmd" }, {
		group = group,
		buffer = bufnr,
		callback = M.save,
	})

	-- render events
	local last_tick = vim.b.changedtick
	vim.api.nvim_create_autocmd("InsertEnter", {
		callback = function()
			last_tick = vim.b.changedtick
		end,
	})
	vim.api.nvim_create_autocmd("InsertLeave", {
		callback = function()
			if vim.b.changedtick ~= last_tick then
				M.render(bufnr)
			end
		end,
	})
	api.nvim_create_autocmd({ "TextChanged" }, {
		group = group,
		buffer = bufnr,
		callback = function()
			M.render(bufnr)
		end,
	})
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	-- make docstrings white
	api.nvim_set_hl(hl_ns, "@string.documentation.python", { link = "Normal" })

	-- most setup will be per file
	api.nvim_create_autocmd("BufReadCmd", {
		pattern = "*.ipynb",
		group = group,
		callback = M.setup_file,
	})
end

return M
