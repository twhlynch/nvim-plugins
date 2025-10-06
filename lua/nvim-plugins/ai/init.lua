local M = {}

local options = {
	fix = {
		enabled = false,
	},
	macro = {
		enabled = false,
	},
}

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	if options.enabled then
		require("nvim-plugins.ai.fix").setup(options.fix)
		require("nvim-plugins.ai.macro").setup(options.macro)
	end
end

return M
