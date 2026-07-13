local M = {}

local options = {
	mapping = {
		["true"] = "false",
		["false"] = "true",
		["on"] = "off",
		["off"] = "on",
		["yes"] = "no",
		["no"] = "yes",
	},
}

function M.toggle_or_normal(normal_key)
	local word = vim.fn.expand("<cword>")
	local replacement = options.mapping[word:lower()]

	if replacement then
		-- preserve capitalisation
		if word:match("^%u+$") then
			replacement = replacement:upper()
		elseif word:match("^%u") then
			replacement = replacement:gsub("^%l", string.upper)
		end

		return ("ciw%s<Esc>"):format(replacement)
	end

	return normal_key
end

function M.setup(opts)
	options.mapping = opts.mapping or options.mapping

	vim.keymap.set("n", "<C-a>", function()
		return M.toggle_or_normal("<C-a>")
	end, { expr = true })

	vim.keymap.set("n", "<C-x>", function()
		return M.toggle_or_normal("<C-x>")
	end, { expr = true })
end

return M
