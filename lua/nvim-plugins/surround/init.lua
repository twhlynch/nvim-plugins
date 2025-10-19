local M = {}

local options = {
	prefix = "s",
	mapping = {
		["()90"] = { "(", ")" },
		["[]"] = { "[", "]" },
		["<>"] = { "<", ">" },
		["{}"] = { "{", "}" },
		["$4"] = { "$$ ", " $$" },
		["|"] = { "|" },
		["'"] = { "'" },
		['"'] = { '"' },
		["`"] = { "`" },
		["*"] = { "*" },
		["_"] = { "_" },
		["%"] = { "%" },
	},
}

-- surround selection
function M.surround(trigger, pref, suff)
	-- visual mode
	local cmd = ":<C-u>normal!`>a" .. suff .. "<Esc>`<i" .. pref .. "<Esc>"
	vim.keymap.set({ "v", "x" }, options.prefix .. trigger, function()
		if vim.fn.mode() == "" then -- visual block
			return cmd .. "`<<C-v>`>" .. string.rep("l", #suff)
		else
			return cmd .. "`<v`>" .. string.rep("l", #pref + #suff)
		end
	end, { noremap = true, silent = true, desc = "Surround selection with " .. pref .. " " .. suff, expr = true })
	-- normal mode
	vim.keymap.set({ "n" }, options.prefix .. trigger, function()
		return "a" .. suff .. "<Esc>" .. string.rep("h", #suff) .. "i" .. pref .. "<Esc>l"
	end, { noremap = true, silent = true, desc = "Surround selection with " .. pref .. " " .. suff, expr = true })
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	for key, value in pairs(options.mapping) do
		for i = 1, #key do
			local trigger = key:sub(i, i)
			M.surround(trigger, value[1], #value > 1 and value[2] or value[1])
		end
	end
end

return M
