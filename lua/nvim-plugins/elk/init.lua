local M = {}

local options = {
	binary = "elk",
	debounce = 400,
	filetypes = { "asm" },
}

-- parse elk --quiet output
-- <severity>: <message> (Line <N>)
local function parse(output)
	local diagnostics = {}

	-- strip ansi
	local clean = string.gsub(output, "\27%[[0-9;]*[a-zA-Z]", "")

	-- for each line
	for line in clean:gmatch("[^\n]+") do
		-- extract parts
		local sev_word, msg, lnum = line:match("^(%a+):%s+(.-)%s+%(Line%s+(%d+)%)")
		local severity = sev_word and M.severity_map[sev_word]
		-- insert diagnostic
		if severity and lnum then
			table.insert(diagnostics, {
				lnum = tonumber(lnum) - 1,
				col = 0,
				severity = severity,
				message = msg,
				source = "elk",
			})
		end
	end

	return diagnostics
end

-- runner
local function run(bufnr, cmd)
	if not vim.api.nvim_buf_is_valid(bufnr) then
		return
	end

	-- create temp file
	local ext = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":e")
	local tmpfile = vim.fn.tempname() .. (ext ~= "" and ("." .. ext) or ".asm")

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local f = io.open(tmpfile, "w")
	if not f then
		return
	end
	f:write(table.concat(lines, "\n"))
	f:close()

	-- run elk on file
	vim.system(
		{ cmd, tmpfile, "--quiet" },
		{ text = true },
		vim.schedule_wrap(function(result)
			-- remove the temp file
			os.remove(tmpfile)
			-- then check buffer
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end

			-- parse diagnostics
			local output = (result.stderr or "") .. (result.stdout or "")
			vim.diagnostic.set(M.ns, bufnr, parse(output))
		end)
	)
end

-- debounce
local timers = {}

local function debounced_run(bufnr, cmd, delay_ms)
	if timers[bufnr] then
		timers[bufnr]:stop()
	end
	timers[bufnr] = vim.defer_fn(function()
		timers[bufnr] = nil
		run(bufnr, cmd)
	end, delay_ms)
end

-- setup
function M.attach(args)
	local bufnr = args.buf

	run(bufnr, options.binary)

	vim.api.nvim_create_autocmd({ "InsertLeave", "BufWritePost", "TextChanged" }, {
		group = M.group,
		buffer = bufnr,
		callback = function()
			debounced_run(bufnr, options.binary, options.debounce)
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		group = M.group,
		buffer = bufnr,
		callback = function()
			if vim.bo[bufnr].modified then
				debounced_run(bufnr, options.binary, options.debounce)
			end
		end,
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = M.group,
		buffer = bufnr,
		callback = function()
			if timers[bufnr] then
				timers[bufnr]:stop()
				timers[bufnr] = nil
			end
			vim.diagnostic.reset(M.ns, bufnr)
		end,
	})
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	M.group = vim.api.nvim_create_augroup("ElkDiagnostics", { clear = true })

	M.ns = vim.api.nvim_create_namespace("elk")

	M.severity_map = {
		Error = vim.diagnostic.severity.ERROR,
		Warning = vim.diagnostic.severity.WARN,
	}

	vim.api.nvim_create_autocmd("FileType", {
		group = M.group,
		pattern = options.filetypes,
		callback = M.attach,
	})
end

return M
