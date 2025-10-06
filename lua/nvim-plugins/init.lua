local M = {}

local options = {}

function M.load(name, opts)
	opts = opts or {}

	local plugin, ok = pcall(require, "nvim-plugins." .. name)
	if ok == true and plugin ~= nil then
		---@diagnostic disable-next-line: undefined-field
		if plugin ~= nil and plugin.setup ~= nil then
			---@diagnostic disable-next-line: undefined-field
			plugin.setup(opts)
		end
	end
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	for name, config in pairs(options) do
		if config ~= nil and config.enabled == true then
			M.load(name, config)
		end
	end
end

return M
