local M = {}

local notebook = require("nvim-plugins.notebook.notebook")
local options = require("nvim-plugins.notebook.options")
local rendering = require("nvim-plugins.notebook.rendering")

function M.setup(opts)
	-- update in place
	for k, v in pairs(vim.tbl_deep_extend("keep", opts or {}, options)) do
		options[k] = v
	end

	rendering.setup()

	-- most setup will be per file
	vim.api.nvim_create_autocmd("BufReadCmd", {
		pattern = "*.ipynb",
		group = notebook.group,
		callback = notebook.setup_file,
	})
end

return M
