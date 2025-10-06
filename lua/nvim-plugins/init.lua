local M = {}

function M.load(name, opts)
	local plugin, ok = pcall(require, "nvim-plugins.lua.nvim-plugins." .. name)
	if ok == true and plugin ~= nil then
		---@diagnostic disable-next-line: undefined-field
		if plugin ~= nil and plugin.setup ~= nil then
			---@diagnostic disable-next-line: undefined-field
			plugin.setup(opts)
			Plugins[name] = plugin
		end
	end
end

function M.setup(opts)
	opts = opts or {}

	Plugins = {}

	for name, config in pairs(opts) do
		if config ~= nil and config.enabled == true then
			M.load(name, config)
		end
	end
end

return M
