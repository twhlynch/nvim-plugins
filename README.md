# A collection of Neovim plugins for my personal use

| Plugin              | Description                                                       | Credit                                 |
| ------------------- | ----------------------------------------------------------------- | -------------------------------------- |
| blame               | Viewing Git blame of all lines in a buffer                        | Based on VSCode                        |
| copy lspconfig      | Quickly copy lspconfig configs into nvims config                  |                                        |
| fff                 | Snacks Picker wrapper on fff.nvim                                 | Based on code from madmaxieee          |
| oil git             | Show git status in oil buffer                                     | Rewrite of benomahony/oil-git.nvim     |
| origami             | Use h and l to open close folds                                   | From chrisgrieser/nvim-origami         |
| pear                | Super simple file pair jumping                                    | From sylvianfranklin/pear              |
| regions             | Mark regions and jump between them with nvim-scrollbar handler    | Based on VSCode                        |
| reminder            | Notify and highlight line numbers when saving unformatted content |                                        |
| reviews             | Show GitHub PR reviews in buffer                                  |                                        |
| scrotodollbar marks | Show marks in nvim-scrollbar                                      | By chrisgrieser                        |
| surround            | Simple selected text surround plugin                              |                                        |
| hipatterns          | Mini hipatterns handlers for various colors, css, and secrets     |                                        |
| scrollbar todo      | Show folke/todo-comments in nvim-scrollbar                        |                                        |
| nolint              | Quickly silent clang warnings                                     |                                        |
| breadcrumbs         | Highlight line numbers with cursor activity                       |                                        |
| inlay               | Inject inlay hints into the buffer                                | Based on Davidyz/inlayhint-filler.nvim |
| auto commit         | Silly plugin that commits after every change                      |                                        |
| templates           | Default content for new files by name and extension               |                                        |
| toggle              | Toggle common booleans with ctrl x & a                            |                                        |
| tasks               | [moved](https://github.com/twhlynch/tasks.nvim)                   |                                        |
| notebook            | [moved](https://github.com/twhlynch/notebook.nvim)                |                                        |
| elk                 | [moved](https://github.com/twhlynch/elk.nvim)                     |                                        |

## Default config

Example for `lazy.nvim`.

All plugins are disabled by default. Changing `enabled` to true will setup that plugin with the options specified overriding the defaults.

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
			pairs = {
				-- {
				-- 	source_dirs = { "src", "source", "sources" },
				-- 	header_dirs = { "include", "includes" },
				-- 	source_exts = { "cpp", "c" },
				-- 	header_exts = { "hpp", "h" },
				-- },
			},
		},
		regions = {
			enabled = false,
			region_markers = {
				"MARK: ",
				"#region ",
			},
			divider = {
				enabled = true,
				hl_group = "RegionDivider",
				char = "─",
			},
			keys = {
				next = "]r",
				prev = "[r",
			},
		},
		reminder = {
			enabled = false,
			notify = print,
			numbers = false, -- highlight line or line numbers
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
			redact = false,
			patterns = {
				hex = "0?[#x]%x%x%x%x?%x?%x?%x?%x?%f[%W]", -- 3 - 8 length hex. # or 0x
				rgb = "rgba?%(%d%d?%d?, ?%d%d?%d?, ?%d%d?%d?,? ?%d?%.?%d%)", -- rgb or rgba css color
				ansi = "%[[34]8;2;%d%d?%d?;%d%d?%d?;%d%d?%d?m%f[%W]", -- r;g;b ansi code for fg or bg
				env = '".-"', -- env values
				redact = ".-#REDACT#", -- redact line containing
			},
		},
		scrollbar_todo = {
			enabled = false,
		},
		nolint = {
			enabled = false,
			key = "gcs",
		},
		breadcrumbs = {
			enabled = false,
			dark_color = "#606079",
			light_color = "#e0a363",
			max = 200,
			max_moves = 2000,
			decay_rate = 0.999,
		},
		inlay = {
			enabled = false,
		},
		auto_commit = {
			enabled = false,
			keymap = "<leader>commit",
			message = function()
				return "auto: " .. os.date("%H:%M:%S")
			end,
		},
		templates = {
			enabled = false,
			templates_dir = vim.fn.stdpath("config") .. "/templates",
		},
		toggle = {
			enabled = false,
			mapping = {
				["true"] = "false",
				["false"] = "true",
				["on"] = "off",
				["off"] = "on",
				["yes"] = "no",
				["no"] = "yes",
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
		{ "<leader>bf", function() Plugins.blame.show_blame() end, desc = "Show file blame", },
		{ "<leader>i", function() Plugins.reminder.ignore_buffer() end, desc = "Toggle ignoring format reminder for buffer", },
		{ "<leader>I", function() Plugins.reminder.toggle() end, desc = "Toggle format reminder", },
		{ "<leader>LSP", function() Plugins.copy_lspconfig.copy_lsp() end, desc = "Copy lsp config", },
		{ "<leader><leader>", function() Plugins.fff.fff() end, desc = "FFF", },
		{ "<leader>Rr", function() Plugins.reviews.get_pr_review_comments() end, desc = "Refresh Reviews", },
		{ "<leader>Ro", function() Plugins.oil_git.update_git_status() end, desc = "Refresh Oil Git", },
		{ "<leader>hI", mode = { "n", "x" }, function() Plugins.inlay.inject_inlay_hints() end, desc = "Inject inlay hints", },
		-- stylua: ignore end
	},
}
````
