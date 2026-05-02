local M = {}

local options = {
	templates_dir = vim.fn.stdpath("config") .. "/templates",
}

local function read_file(path)
	local fd = io.open(path, "r")

	if not fd then
		return nil
	end

	local content = fd:read("*a")
	fd:close()

	return vim.split(content, "\n", { plain = true })
end

local function find_template(filename)
	-- exact filename
	local exact = options.templates_dir .. "/" .. filename

	if vim.fn.filereadable(exact) == 1 then
		return exact
	end

	-- then extension
	local ext = vim.fn.fnamemodify(filename, ":e")

	if ext ~= "" then
		local ext_template = options.templates_dir .. "/." .. ext

		if vim.fn.filereadable(ext_template) == 1 then
			return ext_template
		end
	end

	return nil
end

local function apply_template(args)
	local filename = vim.fn.fnamemodify(args.file, ":t")
	local template = find_template(filename)

	if not template then
		return
	end

	-- dont overwrite existing content
	if vim.api.nvim_buf_line_count(0) > 1 then
		return
	end

	local first = vim.api.nvim_buf_get_lines(0, 0, 1, false)[1]

	if first ~= "" then
		return
	end

	local lines = read_file(template)

	if not lines then
		return
	end

	-- remove trailing empty line
	if lines[#lines] == "" then
		table.remove(lines, #lines)
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function apply_template_oil(url)
	local path = url:gsub("^oil://", "")
	if not path then
		return
	end

	local filename = vim.fn.fnamemodify(path, ":t")
	local template = find_template(filename)

	if not template then
		return
	end

	local content = read_file(template)
	if not content then
		return
	end

	local fd = io.open(path, "w")
	if fd then
		fd:write(table.concat(content, "\n"))
		fd:close()
	end
end

function M.setup(opts)
	options = vim.tbl_deep_extend("force", options, opts or {})

	local group = vim.api.nvim_create_augroup("FileTemplates", { clear = true })

	vim.api.nvim_create_autocmd("BufNewFile", {
		group = group,
		pattern = "*",
		callback = function(args)
			vim.schedule(function()
				apply_template(args)
			end)
		end,
	})

	vim.api.nvim_create_autocmd("User", {
		group = group,
		pattern = "OilActionsPost",
		callback = function(args)
			vim.schedule(function()
				local actions = args.data.actions
				for _, action in ipairs(actions) do
					if action.entry_type == "file" and action.type == "create" then
						apply_template_oil(action.url)
					end
				end
			end)
		end,
	})
end

return M
