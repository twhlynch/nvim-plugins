local M = {}

local options = {
	prefix = "s",
	mapping = {
		["()90"] = { "(", ")" },
		["[]"] = { "[", "]" },
		["<>"] = { "<", ">" },
		["{}"] = { "{", "}" },
		["$4"] = { "$$ ", " $$" },
		"|",
		"'",
		'"',
		"`",
		"*",
		"_",
		"%",
	},
}

-- surround visual selection
function M.surround(trigger, pref, suff)
	if suff == nil then
		suff = pref
	end
	local cmd = ":<C-u>normal!`>a" .. suff .. "<Esc>`<i" .. pref .. "<Esc>"

	vim.keymap.set({ "v", "x" }, options.prefix .. trigger, function()
		if vim.fn.mode() == "" then -- visual block
			return cmd .. "`<<C-v>`>" .. string.rep("l", #suff)
		else
			return cmd .. "`<v`>" .. string.rep("l", #pref + #suff)
		end
	end, { noremap = true, silent = true, desc = "Surround selection with " .. pref .. " " .. suff, expr = true })
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	for key, value in pairs(options.mapping) do
		local triggers = type(value) == "string" and value or key
		for i = 1, #triggers do
			local trigger = triggers:sub(i, i)
			M.surround(trigger, value[1], value[2])
		end
	end
end

return M
