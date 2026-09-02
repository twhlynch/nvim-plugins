local M = {}

local options = {
	hl = "SpellBad",
	add = {},
}

-- stylua: ignore start
local bad_chars = {
	-- controls
	[[\x00-\x08]],     -- C0 controls
					   -- skip \t \n
	[[\x0B-\x1F]],     -- includes \r
	[[\x7F]],          -- DEL
	[[\u0080-\u009F]], -- C1 controls
	-- unicode invisible / formatting
	[[\u00A0]],        -- non-breaking space
	[[\u00AD]],        -- soft hyphen
	[[\u1680]],        -- ogham space
	[[\u2000-\u200A]], -- various spaces
	[[\u034F]],        -- combining grapheme joiner
	[[\u061C]],        -- arabic letter mark
	[[\u115F-\u1160]], -- hangul fillers
	[[\u180E]],        -- mongolian vowel separator
	[[\u200B-\u200F]], -- zero-width / direction
	[[\u2028-\u202F]], -- line/paragraph separators + spaces
	[[\u205F]],        -- mathematical space
	[[\u2060-\u206F]], -- word joiner / bidi controls
	[[\u2800]],        -- braille pattern blank
	[[\u3000]],        -- ideographic space
	[[\uFEFF]],        -- zero width no-break space / bom
	[[\u3164]],        -- hangul filler
	[[\uFFA0]],        -- halfwidth hangul filler
	-- interlinear annotation / object replacement
	[[\uFFF9-\uFFFC]],
	-- wraps around to ascii lol
	-- [[\uE0020-\uE007F]], -- unicode variation / formatting ranges
	-- [[\u1D173-\u1D17A]], -- musical symbols
}
-- stylua: ignore end

local matched_windows = {}

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	-- highlight non ascii chars
	vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
		pattern = "*",
		callback = function()
			local win = vim.api.nvim_get_current_win()

			if matched_windows[win] then
				return
			end
			matched_windows[win] = true

			local chars = table.concat(vim.list_extend(vim.deepcopy(bad_chars), options.add))
			vim.fn.matchadd(options.hl, "[" .. chars .. "]")
		end,
	})
end

return M
