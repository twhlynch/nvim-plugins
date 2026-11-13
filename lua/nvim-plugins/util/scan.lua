local M = {}

-- Tracks buffer edits only rescanning line ranges that change
-- Scans can be limited to the visible window range and a cheap
-- pre-check runs before the expensive matcher.
local Scanner = {}
Scanner.__index = Scanner

local function eq(a, b)
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for k, v in pairs(a) do
		if b[k] ~= v then
			return false
		end
	end
	for k in pairs(b) do
		if a[k] == nil then
			return false
		end
	end
	return true
end

--- Build a case-insensitive plain substring predicate from needles.
--- Returns nil when there is nothing to check (scan is unrestricted).
--- @param needles string[]
--- @return (fun(line: string): boolean)?
function M.matcher(needles)
	if type(needles) ~= "table" then
		return nil
	end

	local lowered = {}
	for i, needle in ipairs(needles) do
		lowered[i] = string.lower(needle)
	end
	if #lowered == 0 then
		return nil
	end

	return function(line)
		local l = string.lower(line)
		for i = 1, #lowered do
			if l:find(lowered[i], 1, true) then
				return true
			end
		end
		return false
	end
end

--- Visible line range of a window showing bufnr, widened by margin.
--- Returns nil when the buffer is not displayed anywhere (caller should scan all).
--- @param bufnr integer
--- @param margin integer | nil
--- @return integer?, integer?
function M.visible_range(bufnr, margin)
	margin = margin or 400

	local win
	for _, w in ipairs(vim.fn.win_findbuf(bufnr)) do
		if vim.api.nvim_win_is_valid(w) then
			win = w
			break
		end
	end
	if not win then
		return nil
	end

	local first, last
	vim.api.nvim_win_call(win, function()
		first = vim.fn.line("w0")
		last = vim.fn.line("w$")
	end)

	return math.max(1, first - margin), last + margin
end

local function add_dirty(self, first, last)
	if last < first then
		last = first
	end

	local dirty = self.dirty
	dirty[#dirty + 1] = { first, last }
	if #dirty == 1 then
		return
	end

	table.sort(dirty, function(a, b)
		return a[1] < b[1]
	end)

	local merged = { dirty[1] }
	for i = 2, #dirty do
		local prev = merged[#merged]
		local cur = dirty[i]
		if cur[1] <= prev[2] + 1 then
			if cur[2] > prev[2] then
				prev[2] = cur[2]
			end
		else
			merged[#merged + 1] = cur
		end
	end

	self.dirty = merged
end

--- Drop results for removed lines, shift results
--- after the edited range and mark the replaced lines for rescan.
--- @param first integer 0-based first changed line
--- @param last_old integer 0-based end of changed range in the old text
--- @param last_new integer 0-based end of changed range in the new text
local function apply_change(self, first, last_old, last_new)
	local results = self.results
	local mutated = false

	for l = first + 1, last_old do
		if results[l] ~= nil then
			results[l] = nil
			mutated = true
		end
	end

	local delta = last_new - last_old
	if delta ~= 0 then
		local moved = {}
		for l in pairs(results) do
			if l > last_old then
				moved[#moved + 1] = l
			end
		end
		if #moved > 0 then
			table.sort(moved)
			local values = {}
			for i, l in ipairs(moved) do
				values[i] = results[l]
				results[l] = nil
			end
			for i, l in ipairs(moved) do
				results[l + delta] = values[i]
			end
			mutated = true
		end
	end

	if mutated then
		self.version = self.version + 1
	end

	add_dirty(self, first + 1, math.max(last_new, first + 1))
end

local function attach(self)
	local ok, attached = pcall(vim.api.nvim_buf_attach, self.bufnr, false, {
		-- returning a truthy value detaches, so only do that when destroyed
		on_lines = function(_, _, _, first, last_old, last_new)
			if self.detached then
				return true
			end
			apply_change(self, first, last_old, last_new)
		end,
		on_reload = function()
			if self.detached then
				return
			end
			self:invalidate()
		end,
		on_detach = function()
			self.detached = true
			self.results = {}
			self.dirty = {}
		end,
	})
	self.attached = ok and attached or false
end

--- @class Scan.Opts
--- @field match fun(line: string, lnum: integer): any | nil the expensive check
--- @field needles string[] | fun(bufnr: integer): string[] | nil cheap pre-check needles
--- @field precheck (fun(line: string): boolean) | nil cheap pre-check
--- @field margin integer | nil extra lines around the visible range

--- Create a scanner for a buffer.
--- @param bufnr integer
--- @param opts Scan.Opts
function M.new(bufnr, opts)
	local self = setmetatable({
		bufnr = bufnr,
		opts = opts,
		results = {},
		dirty = { { 1, math.huge } },
		version = 0,
		attached = false,
		detached = false,
		matcher = nil,
		matcher_src = nil,
	}, Scanner)

	self.tick = vim.api.nvim_buf_get_changedtick(bufnr)

	attach(self)
	return self
end

function Scanner:invalidate()
	if next(self.results) ~= nil then
		self.version = self.version + 1
	end
	self.results = {}
	self.dirty = { { 1, math.huge } }
end

function Scanner:destroy()
	self.detached = true
	self.results = {}
	self.dirty = {}
end

local function refresh_matcher(self)
	local src = self.opts.needles
	if type(src) == "function" then
		local ok, needles = pcall(src, self.bufnr)
		self.matcher = ok and M.matcher(needles) or nil
		self.matcher_src = nil
	elseif type(src) == "table" then
		if self.matcher_src ~= src then
			self.matcher = M.matcher(src)
			self.matcher_src = src
		end
	end
end

function Scanner:scan_range(first, last)
	local lines = vim.api.nvim_buf_get_lines(self.bufnr, first - 1, last, false)
	local match = self.opts.match
	local precheck = self.opts.precheck
	local matcher = self.matcher
	local changed = false

	for i = 1, #lines do
		local lnum = first + i - 1
		local line = lines[i]
		local value

		local plausible = true
		if precheck then
			plausible = precheck(line) == true
		end
		if plausible and (not matcher or matcher(line)) then
			value = match(line, lnum)
		end

		local old = self.results[lnum]
		if not eq(old, value) then
			self.results[lnum] = value
			changed = true
		end
	end

	if changed then
		self.version = self.version + 1
	end
	return changed
end

--- Scan dirty lines intersecting [first, last].
--- @param first integer | nil
--- @param last integer | nil
--- @return boolean changed
function Scanner:update(first, last)
	if self.detached then
		return false
	end

	if not self.attached then
		local tick = vim.api.nvim_buf_get_changedtick(self.bufnr)
		if tick ~= self.tick then
			self:invalidate()
			self.tick = tick
		end
	end

	local line_count = vim.api.nvim_buf_line_count(self.bufnr)
	first = math.max(first or 1, 1)
	last = math.min(last or line_count, line_count)

	-- drop or clamp dirty ranges invalidated by the buffer shrinking
	local dirty = {}
	for _, r in ipairs(self.dirty) do
		local f = math.max(r[1], 1)
		local l = math.min(r[2], line_count)
		if f <= l then
			dirty[#dirty + 1] = { f, l }
		end
	end
	self.dirty = dirty

	if #dirty == 0 then
		return false
	end

	refresh_matcher(self)

	local changed = false
	local remaining = {}
	for _, r in ipairs(self.dirty) do
		local rf = math.max(r[1], first)
		local rl = math.min(r[2], last)
		if rf <= rl then
			if self:scan_range(rf, rl) then
				changed = true
			end
			if r[1] < rf then
				remaining[#remaining + 1] = { r[1], rf - 1 }
			end
			if r[2] > rl then
				remaining[#remaining + 1] = { rl + 1, r[2] }
			end
		else
			remaining[#remaining + 1] = r
		end
	end
	self.dirty = remaining

	return changed
end

local function collect(self, first, last)
	local out = {}
	for lnum, value in pairs(self.results) do
		if lnum >= first and lnum <= last then
			out[#out + 1] = { line = lnum, value = value }
		end
	end
	table.sort(out, function(a, b)
		return a.line < b.line
	end)
	return out
end

--- Entries in [first, last] without scanning.
--- @param first integer | nil
--- @param last integer | nil
function Scanner:entries(first, last)
	local line_count = vim.api.nvim_buf_line_count(self.bufnr)
	return collect(self, math.max(first or 1, 1), math.min(last or line_count, line_count))
end

--- Ensure [first, last] is scanned and return its entries.
--- @param first integer | nil
--- @param last integer | nil
function Scanner:fetch(first, last)
	self:update(first, last)
	return self:entries(first, last)
end

--- Ensure everything is scanned and return all entries.
function Scanner:all()
	return self:fetch()
end

--- Scan dirty lines in the visible window range and return those entries.
--- @param margin integer | nil
function Scanner:visible(margin)
	local first, last = M.visible_range(self.bufnr, margin or self.opts.margin)
	if not first then
		return self:all()
	end
	return self:fetch(first, last)
end

return M
