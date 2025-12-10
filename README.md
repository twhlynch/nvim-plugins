# A collection of Neovim plugins for my personal use

## lazy.nvim
````lua
return {
	"twhlynch/nvim-plugins",
	opts = {
		blame = { enabled = false },
		copy_lspconfig = { enabled = false },
		fff = { enabled = false },
		oil_git = {
			enabled = false,
			highlight = {
				OilGitAdded = { fg = "#7fa563" },
				OilGitModified = { fg = "#f3be7c" },
				OilGitDeleted = { fg = "#d8647e" },
				OilGitRenamed = { fg = "#cba6f7" },
				OilGitUntracked = { fg = "#c48282" },
			},
		},
		origami = { enabled = false },
		pear = {
			enabled = false,
			source_exts = { "c", "cpp", "frag", "html" },
			header_exts = { "h", "hpp", "vert", "js", "css" },
		},
		regions = {
			enabled = false,
			region_markers = {
				"MARK: ",
				"#region ",
			},
		},
		reminder = {
			enabled = false,
			notify = print,
		},
		reviews = {
			enabled = false,
			interval = 1800, -- 30 minutes
			debug = false,
			highlight = nil, -- can be a hex string e.g. "#7E98E8"
			integrations = {
				scrollbar = false,
			},
		},
		scrollbar_marks = { enabled = false },
		surround = {
			enabled = false,
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
		},
		hipatterns = {
			enabled = false,
			hex = false,
			rgb = false,
			ansi = false,
			env = false,
			css = false,
			patterns = {
				hex = "0?[#x]%x%x%x%x?%x?%x?%x?%x?%f[%W]", -- 3 - 8 length hex. # or 0x
				rgb = "rgba?%(%d%d?%d?, ?%d%d?%d?, ?%d%d?%d?,? ?%d?%.?%d%)", -- rgb or rgba css color
				ansi = "%[[34]8;2;%d%d?%d?;%d%d?%d?;%d%d?%d?m%f[%W]", -- r;g;b ansi code for fg or bg
				env = '".-"', -- env values
			},
		},
		scrollbar_todo = {
			enabled = true,
		},
		nolint = {
			enabled = true,
			key = "gcs",
		},
	},
	keys = {
		---@diagnostic disable: undefined-global
		-- stylua: ignore start
		{ "h", function() Plugins.origami.h() end, desc = "Origami h", },
		{ "l", function() Plugins.origami.l() end, desc = "Origami l", },
		{ "<leader>jp", function() Plugins.pear.jump_pair() end, desc = "Jump file pair", },
		{ "<leader>K", function() Plugins.reviews.get_current_line_comments() end, desc = "Show line PR Review Comments", },
		{ "]r", function() Plugins.regions.goto_next_region() end, desc = "Next region", },
		{ "[r", function() Plugins.regions.goto_prev_region() end, desc = "Previous region", },
		{ "<leader>bf", function() Plugins.blame.show_blame() end, desc = "Show file blame", },
		{ "<leader>i", function() Plugins.reminder.ignore_buffer() end, desc = "Toggle ignoring format reminder for buffer", },
		{ "<leader>I", function() Plugins.reminder.toggle() end, desc = "Toggle format reminder", },
		{ "<leader>LSP", function() Plugins.copy_lspconfig.copy_lsp() end, desc = "Copy lsp config", },
		{ "<leader><leader>", function() Plugins.fff.fff() end, desc = "FFF", },
		{ "<leader>Rr", function() Plugins.reviews.get_pr_review_comments() end, desc = "Refresh Reviews", },
		{ "<leader>Ro", function() Plugins.oil_git.update_git_status() end, desc = "Refresh Oil Git", },
		-- stylua: ignore end
	},
}
````

