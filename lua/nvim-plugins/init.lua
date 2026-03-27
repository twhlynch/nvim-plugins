local M = {}

-- expose plugins to object
setmetatable(M, {
	__index = function(t, k)
		t[k] = require("nvim-plugins." .. k)
		return rawget(t, k)
	end,
})

-- make Plugins object global
_G.Plugins = M

function M.load(name, opts)
	local plugin = require("nvim-plugins." .. name)
	-- safe setup
	if plugin ~= nil then
		if plugin ~= nil and plugin.setup ~= nil then
			plugin.setup(opts)
		end
	end
end

-- actual plugin setup
function M.setup(opts)
	opts = opts or {}
	for name, config in pairs(opts) do
		-- load enabled configs
		if config ~= nil and config.enabled == true then
			M.load(name, config)
		end
	end
end

return M
