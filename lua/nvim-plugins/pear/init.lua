local M = {}

local options = {
	pairs = {
		-- {
		-- 	source_dirs = { "src", "source", "sources" },
		-- 	header_dirs = { "include", "includes" },
		-- 	source_exts = { "cpp", "c", "cc", "cxx" },
		-- 	header_exts = { "hpp", "h", "hxx" },
		-- },
		-- {
		-- 	source_exts = { "frag", "fs" },
		-- 	header_exts = { "vert", "vs" },
		-- },
		-- {
		-- 	source_exts = { "html" },
		-- 	header_exts = { "js", "css" },
		-- },
	},
}

-- MARK: helpers

--- @param path string
local function split_ext(path)
	local ext = vim.fn.fnamemodify(path, ":e")
	if ext == "" then
		return path, ""
	end
	return vim.fn.fnamemodify(path, ":r"), ext
end

--- @param root string
--- @param exts string[]
local function try_extensions(root, exts)
	for _, ext in ipairs(exts) do
		local candidate = root .. "." .. ext
		if vim.fn.filereadable(candidate) == 1 then
			return candidate
		end
	end
	return nil
end

-- MARK: core

--- @param file string
--- @param pair table
local function find_pair(file, pair)
	local root, ext = split_ext(file)

	local is_source = vim.tbl_contains(pair.source_exts, ext)
	local is_header = vim.tbl_contains(pair.header_exts, ext)
	if not (is_source or is_header) then
		return nil
	end

	local target_exts = {}
	if is_source then
		for _, extension in ipairs(pair.header_exts or {}) do
			table.insert(target_exts, extension)
		end
	end
	if is_header then
		for _, extension in ipairs(pair.source_exts or {}) do
			table.insert(target_exts, extension)
		end
	end

	-- check sibling
	local sibling = try_extensions(root, target_exts)
	if sibling and sibling ~= file then
		return sibling
	end

	-- check dir
	local from_dirs = {}
	local to_dirs = {}
	for _, dir in ipairs(pair.source_dirs or {}) do
		if is_source then
			table.insert(from_dirs, dir)
		end
		if is_header then
			table.insert(to_dirs, dir)
		end
	end
	for _, dir in ipairs(pair.header_dirs or {}) do
		if is_header then
			table.insert(from_dirs, dir)
		end
		if is_source then
			table.insert(to_dirs, dir)
		end
	end

	if #from_dirs == 0 or #to_dirs == 0 then
		return nil
	end

	local norm_root = vim.fs.normalize(root)

	for _, from_dir in ipairs(from_dirs) do
		local pattern = "(.*/" .. vim.pesc(from_dir) .. ")/(.*)"
		local base, relative_stem = norm_root:match(pattern)

		if base and relative_stem then
			for _, to_dir in ipairs(to_dirs) do
				local target_base = base:match("^(.*)/" .. from_dir .. "$") .. "/" .. to_dir
				local found = try_extensions(target_base .. "/" .. relative_stem, target_exts)

				if found and found ~= file then
					return found
				end
			end
		end
	end

	return nil
end

-- MARK: api

function M.jump_pair()
	local file = vim.fs.normalize(vim.fn.expand("%:p"))

	for _, pair in ipairs(options.pairs) do
		local target = find_pair(file, pair)

		if target then
			vim.cmd.edit(vim.fn.fnameescape(target))
			vim.print(vim.fn.fnamemodify(file, ":~:.") .. " -> " .. vim.fn.fnamemodify(target, ":~:."))
			return
		end
	end

	print("no file pair found.")
end

--- @param opts table
function M.setup(opts)
	options = vim.tbl_deep_extend("force", options, opts or {})
end

return M
