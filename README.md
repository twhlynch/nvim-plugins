# nvim-plugins

A collection of Neovim plugins for my personal use

| Plugin          | Description                                                         | Credit                                 |
| --------------- | ------------------------------------------------------------------- | -------------------------------------- |
| blame           | Viewing Git blame of all lines in a buffer                          | Based on VSCode                        |
| copy lspconfig  | Quickly copy lspconfig configs into nvims config                    |                                        |
| fff             | Snacks Picker wrapper on fff.nvim                                   | Based on code from madmaxieee          |
| oil git         | Show git status in oil buffer                                       | Rewrite of benomahony/oil-git.nvim     |
| origami         | Use h and l to open close folds                                     | From chrisgrieser/nvim-origami         |
| pear            | Super simple file pair jumping                                      | From sylvianfranklin/pear              |
| regions         | Mark regions and jump between them with nvim-scrollbar handler      | Based on VSCode                        |
| reminder        | Notify and highlight line numbers when saving unformatted content   |                                        |
| reviews         | Show GitHub PR reviews in buffer                                    |                                        |
| scrollbar marks | Show marks in nvim-scrollbar                                        | By chrisgrieser                        |
| surround        | Simple selected text surround plugin                                |                                        |
| hipatterns      | Mini hipatterns handlers for various colors, css, and secrets       |                                        |
| scrollbar todo  | Show folke/todo-comments in nvim-scrollbar                          |                                        |
| nolint          | Quickly silent clang warnings                                       |                                        |
| breadcrumbs     | Highlight line numbers with cursor activity                         |                                        |
| inlay           | Inject inlay hints into the buffer                                  | Based on Davidyz/inlayhint-filler.nvim |
| auto commit     | Silly plugin that commits after every change                        |                                        |
| templates       | Default content for new files by name and extension                 |                                        |
| toggle          | Toggle common booleans with ctrl x & a                              |                                        |
| typst preview   | Buggy live typst pdf viewer                                         |                                        |
| tasks           | [moved to tasks.nvim](https://github.com/twhlynch/tasks.nvim)       |                                        |
| notebook        | [moved to notebook.nvim](https://github.com/twhlynch/notebook.nvim) |                                        |
| elk             | [moved to elk.nvim](https://github.com/twhlynch/elk.nvim)           |                                        |

## Default config

Example for `lazy.nvim`.

All plugins are disabled by default. Changing `enabled` to true will load and
setup that plugin with the options specified overriding the defaults.

```lua
return {
	"twhlynch/nvim-plugins",
	opts = {
		blame = {
			enabled = false,
			key = "<leader>bf",
		},
		copy_lspconfig = {
			enabled = false,
			key = "<leader>LSP",
		},
		fff = {
			enabled = false,
			key = "<leader><leader>",
		},
		oil_git = {
			enabled = false,
			refresh_key = "<leader>Ro",
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
			key = "<leader>jp",
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
			ignore_key = "<leader>i",
			toggle_key = "<leader>I",
			notify = print,
			numbers = false, -- highlight line or line numbers
		},
		reviews = {
			view_key = "<leader>K",
			refresh_key = "<leader>Rr",
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
			key = "<leader>hI",
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
		typst_preview = {
			enabled = true,
			key = "<leader>pt",
			left = "<Left>",
			right = "<Right>",
		},
	},
}
```
