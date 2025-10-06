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
			enabled = true,
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
		-- stylua: ignore start
		{ "h", require("nvim-plugins.origami").h, desc = "Origami h", },
		{ "l", require("nvim-plugins.origami").l, desc = "Origami l", },
		{ "<leader>jp", require("nvim-plugins.pear").jump_pair, desc = "Jump file pair", },
		{ "<leader>K", require("nvim-plugins.reviews").get_current_line_comments, desc = "Show line PR Review Comments", },
		{ "<leader>jp", require("nvim-plugins.pear").jump_pair, desc = "Jump file pair", },
		{ "]r", require("nvim-plugins.regions").goto_next_region, desc = "Next region", },
		{ "[r", require("nvim-plugins.regions").goto_prev_region, desc = "Previous region", },
		{ "<leader>bf", require("nvim-plugins.blame").show_blame, desc = "Show file blame", },
		{ "<leader>i", require("nvim-plugins.reminder").ignore_buffer, desc = "Toggle ignoring format reminder for buffer", },
		{ "<leader>I", require("nvim-plugins.reminder").toggle, desc = "Toggle format reminder", },
		{ "<leader>LSP", require("nvim-plugins.copy_lspconfig").copy_lsp, desc = "Copy lsp config", },
		{ "<leader>hb", require("nvim-plugins.history").get_blames, desc = "Show line blame history", },
		{ "<leader>lq", require("nvim-plugins.ai_fix").ask, desc = "Ask about error", },
		{ "<leader>lq", require("nvim-plugins.ai_fix").visual_ask, desc = "Ask about error", mode = { "x" }, },
		{ "<leader>lQ", require("nvim-plugins.ai_fix").complex_ask, desc = "Ask about error in detail", },
		{ "<leader>lQ", require("nvim-plugins.ai_fix").complex_visual_ask, desc = "Ask about error in detail", mode = { "x" }, },
		{ "<leader>q", require("nvim-plugins.ai_macro").ask, desc = "Ask to run a macro", mode = { "n", "x" }, },
		{ "<leader><leader>", require("nvim-plugins.fff").fff, desc = "FFF", },
		{ "<leader>Rr", require("nvim-plugins.reviews").get_pr_review_comments, desc = "Refresh Reviews", },
		{ "<leader>Ro", require("nvim-plugins.oil_git").update_git_status, desc = "Refresh Oil Git", },
		-- stylua: ignore end
	},
}
````

