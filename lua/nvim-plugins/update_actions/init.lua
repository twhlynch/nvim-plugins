local M = {}

--- @class UpdateActionsOptions
--- @field ttl_days number cache TTL in days
--- @field severity integer vim diagnostic severity level

local options = {
	ttl_days = 7,
	severity = vim.diagnostic.severity.WARN,
}

local ns_id = vim.api.nvim_create_namespace("UpdateActions")

--- @class UpdateActionsCacheEntry
--- @field checked number unix time the version was fetched
--- @field version string latest version without the "v" prefix

--- @type table<string, UpdateActionsCacheEntry>
local cache = {}

local cache_file = vim.fn.stdpath("cache") .. "/update-actions.json"

--- Load the version cache from disk once per session
--- @return table<string, UpdateActionsCacheEntry>
local function load_cache()
	if next(cache) ~= nil then
		return cache
	end
	local f = io.open(cache_file, "r")
	if not f then
		return cache
	end
	local ok, data = pcall(vim.json.decode, f:read("*a"))
	f:close()
	if ok and type(data) == "table" then
		cache = data
	end
	return cache
end

--- Write the version cache to disk
local function save_cache()
	local f = io.open(cache_file, "w")
	if f then
		f:write(vim.json.encode(cache))
		f:close()
	end
end

--- Fetch the latest version of a github action, using the cache when fresh
--- @param action string action in "owner/repo" form
--- @param callback fun(version: string?) called with the latest version, or nil if unknown
local function get_latest_version(action, callback)
	local now = os.time()
	local cached = load_cache()[action]
	if cached and now - cached.checked < options.ttl_days * 24 * 60 * 60 then
		callback(cached.version)
		return
	end

	vim.system({
		"curl",
		"-sfL",
		"-H",
		"Accept: application/vnd.github+json",
		"https://api.github.com/repos/" .. action .. "/releases/latest",
	}, { text = true }, function(res)
		local version = nil
		if res.code == 0 and res.stdout then
			local ok, decoded = pcall(vim.json.decode, res.stdout)
			if ok and decoded.tag_name then
				version = decoded.tag_name:gsub("^v", "")
			end
		end
		if version then
			cache[action] = { checked = now, version = version }
			save_cache()
		end

		vim.schedule(function()
			callback(version)
		end)
	end)
end

--- Extract the major version from a version string
--- @param version string
--- @return string?
local function major_version(version)
	return version:gsub("^v", ""):match("^%d+")
end

--- Check whether a buffer is a github workflow file
--- @param bufnr integer
--- @return boolean
local function is_workflow_file(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	return name:find("%.github/workflows/[^/]+%.ya?ml$") ~= nil
end

--- @class UpdateActionsUse
--- @field line number 0-based line index
--- @field col number 0-based column of the "uses:" keyword
--- @field action string action in "owner/repo" form
--- @field ref string version ref as written in the file

--- Find all `uses: owner/repo@ref` in a buffer, skipping local actions
--- @param bufnr integer
--- @return UpdateActionsUse[]
local function find_actions(bufnr)
	local found = {}
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	for i, line in ipairs(lines) do
		local pos, action, ref = line:match("()uses:%s*([%w%-%._/]+)@([%w%-%.]+)")
		if action and not action:find("^%./") and not action:find("^%.%./") then
			table.insert(found, { line = i - 1, col = pos - 1, action = action, ref = ref })
		end
	end
	return found
end

--- Clear all diagnostics for a buffer
--- @param bufnr integer
local function clear_diagnostics(bufnr)
	vim.diagnostic.set(ns_id, bufnr, {})
end

--- Check the actions in a buffer and set update diagnostics
--- @param bufnr? integer defaults to the current buffer
function M.check(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not is_workflow_file(bufnr) then
		return
	end

	local actions = find_actions(bufnr)
	if #actions == 0 then
		clear_diagnostics(bufnr)
		return
	end

	-- fetch latest versions once per unique action
	local seen, unique = {}, {}
	for _, a in ipairs(actions) do
		if not seen[a.action] then
			seen[a.action] = true
			table.insert(unique, a.action)
		end
	end

	local pending = #unique
	local latest = {}
	for _, action in ipairs(unique) do
		get_latest_version(action, function(version)
			if version then
				latest[action] = version
			end
			pending = pending - 1
			if pending > 0 then
				return
			end
			-- all fetched, buffer may have changed
			if not vim.api.nvim_buf_is_valid(bufnr) then
				return
			end
			local diagnostics = {}
			for _, a in ipairs(find_actions(bufnr)) do
				local current_major = major_version(a.ref)
				local new_major = major_version(latest[a.action] or "")
				-- only suggest when the current ref is a major version behind the latest major
				if current_major and new_major and tonumber(current_major) < tonumber(new_major) then
					table.insert(diagnostics, {
						lnum = a.line,
						col = a.col,
						severity = options.severity,
						message = a.action .. "@" .. a.ref .. " -> " .. a.action .. "@" .. new_major,
						source = "update-actions",
					})
				end
			end
			vim.diagnostic.set(ns_id, bufnr, diagnostics)
		end)
	end
end

--- Debounce per-buffer rechecks on text changes
local debounce_timers = {}

--- @param bufnr integer
local function schedule_check(bufnr)
	local timer = debounce_timers[bufnr]
	if timer then
		timer:stop()
		timer:close()
	end
	debounce_timers[bufnr] = vim.defer_fn(function()
		debounce_timers[bufnr] = nil
		M.check(bufnr)
	end, 500)
end

--- @param opts? UpdateActionsOptions
function M.setup(opts)
	options = vim.tbl_deep_extend("force", options, opts or {})

	local augroup = vim.api.nvim_create_augroup("UpdateActions", { clear = true })

	vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
		group = augroup,
		callback = function(args)
			if is_workflow_file(args.buf) then
				vim.defer_fn(function()
					M.check(args.buf)
				end, 100)
			end
		end,
	})

	vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
		group = augroup,
		callback = function(args)
			if is_workflow_file(args.buf) then
				schedule_check(args.buf)
			end
		end,
	})
end

return M
