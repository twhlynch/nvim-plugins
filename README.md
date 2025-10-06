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
			patterns = {
				hex = "0?[#x]%x%x%x%x?%x?%x?%x?%x?%f[%W]", -- 3 - 8 length hex. # or 0x
				rgb = "rgba?%(%d%d?%d?, ?%d%d?%d?, ?%d%d?%d?,? ?%d?%.?%d%)", -- rgb or rgba css color
				ansi = "%[[34]8;2;%d%d?%d?;%d%d?%d?;%d%d?%d?m%f[%W]", -- r;g;b ansi code for fg or bg
			},
		}
		ai = {
			enabled = false,
			fix = {
				enabled = false,
				prompt = {
					template = [[
in __file__:
```
__lines__
```

errors:
```
__errors__
```

__prompt__

]],
					simple = [[
fix the code. keep your solution short and respond with only fixed lines, not surrounding code.
if there is no error provided, figure out the issue anyway.
specify the correct language in the markdown codeblock.
you must respond with only 1 codeblock and nothing else.
]],
					complex = [[
respond with an explaination of the code, then an explaination of the error.
then an explaination of how to fix the error with the full solution in code.
if there is no error provided, find issues in the code and fix them.
]],
				},
			},
			macro = {
				enabled = false,
				prompt = {
					template = [[
in __file__:
```
__lines__
```

errors:
```
__errors__
```

__prompt__

]],
					simple = [[
fix the code. keep your solution short and respond with only fixed lines, not surrounding code.
if there is no error provided, figure out the issue anyway.
specify the correct language in the markdown codeblock.
you must respond with only 1 codeblock and nothing else.
]],
					complex = [[
respond with an explaination of the code, then an explaination of the error.
then an explaination of how to fix the error with the full solution in code.
if there is no error provided, find issues in the code and fix them.
]],
				},
			},
		},
	},
	keys = {
		---@diagnostic disable: undefined-global
		-- stylua: ignore start
		{ "h", function() Plugins.origami.h() end, desc = "Origami h", },
		{ "l", function() Plugins.origami.l() end, desc = "Origami l", },
		{ "<leader>jp", function() Plugins.pear.jump_pair() end, desc = "Jump file pair", },
		{ "<leader>K", function() Plugins.reviews.get_current_line_comments() end, desc = "Show line PR Review Comments", },
		{ "<leader>jp", function() Plugins.pear.jump_pair() end, desc = "Jump file pair", },
		{ "]r", function() Plugins.regions.goto_next_region() end, desc = "Next region", },
		{ "[r", function() Plugins.regions.goto_prev_region() end, desc = "Previous region", },
		{ "<leader>bf", function() Plugins.blame.show_blame() end, desc = "Show file blame", },
		{ "<leader>i", function() Plugins.reminder.ignore_buffer() end, desc = "Toggle ignoring format reminder for buffer", },
		{ "<leader>I", function() Plugins.reminder.toggle() end, desc = "Toggle format reminder", },
		{ "<leader>LSP", function() Plugins.copy_lspconfig.copy_lsp() end, desc = "Copy lsp config", },
		{ "<leader>lq", function() Plugins.ai_fix.ask() end, desc = "Ask about error", },
		{ "<leader>lq", function() Plugins.ai_fix.visual_ask() end, desc = "Ask about error", mode = { "x" }, },
		{ "<leader>lQ", function() Plugins.ai_fix.complex_ask() end, desc = "Ask about error in detail", },
		{ "<leader>lQ", function() Plugins.ai_fix.complex_visual_ask() end, desc = "Ask about error in detail", mode = { "x" }, },
		{ "<leader>q", function() Plugins.ai_macro.ask() end, desc = "Ask to run a macro", mode = { "n", "x" }, },
		{ "<leader><leader>", function() Plugins.fff.fff() end, desc = "FFF", },
		{ "<leader>Rr", function() Plugins.reviews.get_pr_review_comments() end, desc = "Refresh Reviews", },
		{ "<leader>Ro", function() Plugins.oil_git.update_git_status() end, desc = "Refresh Oil Git", },
		-- stylua: ignore end
	},
}
````

