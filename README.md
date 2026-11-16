# nvim-plugins

A collection of Neovim plugins for my personal use

| Plugin          | Description                                                         | Credit                                 |
| --------------- | ------------------------------------------------------------------- | -------------------------------------- |
| copy lspconfig  | Quickly copy lspconfig configs into nvims config                    |                                        |
| origami         | Use h and l to open close folds                                     | From chrisgrieser/nvim-origami         |
| regions         | Mark regions and jump between them with nvim-scrollbar handler      | Based on VSCode                        |
| pear            | Super simple file pair jumping                                      | From sylvianfranklin/pear              |
| reminder        | Notify and highlight line numbers when saving unformatted content   |                                        |
| nolint          | Quickly silent clang warnings                                       |                                        |
| hipatterns      | Mini hipatterns handlers for various colors, css, and secrets       |                                        |
| surround        | Simple selected text surround plugin                                |                                        |
| scrollbar todo  | Show folke/todo-comments in nvim-scrollbar                          |                                        |
| inlay           | Inject inlay hints into the buffer                                  | Based on Davidyz/inlayhint-filler.nvim |
| templates       | Default content for new files by name and extension                 |                                        |
| toggle          | Toggle common booleans with ctrl x & a                              |                                        |
| ufo folds       | Specific fold handler for nvim ufo                                  |                                        |
| badchars        | Highlight invisible characters                                      |                                        |
| simple_todo     | Simple TODO list popup with autosave to a specified file            |                                        |
| blame           | Viewing Git blame of all lines in a buffer                          | Based on VSCode                        |
| breadcrumbs     | Highlight line numbers with cursor activity                         |                                        |
| scrollbar marks | Show marks in nvim-scrollbar                                        | By chrisgrieser                        |
| oil git         | Show git status in oil buffer                                       | Rewrite of benomahony/oil-git.nvim     |
| reviews         | Show GitHub PR reviews in buffer                                    |                                        |
| fff             | Snacks Picker wrapper on fff.nvim                                   | Based on code from madmaxieee          |
| auto commit     | Silly plugin that commits after every change                        |                                        |
| typst preview   | Buggy live typst pdf viewer                                         |                                        |
| tasks           | [moved to tasks.nvim](https://github.com/twhlynch/tasks.nvim)       |                                        |
| notebook        | [moved to notebook.nvim](https://github.com/twhlynch/notebook.nvim) |                                        |
| elk             | [moved to elk.nvim](https://github.com/twhlynch/elk.nvim)           |                                        |

## Default config

Example for `lazy.nvim`.

All plugins are disabled by default. Changing `enabled` to true in a plugins
options will setup that plugin with the options specified overriding the
defaults.

Base config:

```lua
return {
	"twhlynch/nvim-plugins",
	opts = {
		-- plugin options go here
		-- example = { enabled = true }
	}
}
```

Plugin options:

<details><summary>blame</summary>

```lua
blame = {
	enabled = true,
	key = "<leader>bf",
}
```

</details>

<details><summary>copy_lspconfig</summary>

```lua
copy_lspconfig = {
	enabled = true,
	key = "<leader>LSP",
},
```

</details>

<details><summary>origami</summary>

```lua
origami = {
	enabled = true,
},
```

</details>

<details><summary>pear</summary>

```lua
pear = {
	enabled = true,
	key = "<leader>jp",
	pairs = {
		-- {
		-- 	source_dirs = { "src", "source", "sources" },
		-- 	header_dirs = { "include", "includes" },
		-- 	source_exts = { ".cpp", ".c" },
		-- 	header_exts = { ".hpp", ".h" },
		-- },
	},
},
```

</details>

<details><summary>regions</summary>

```lua
regions = {
	enabled = true,
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
```

</details>

<details><summary>reminder</summary>

```lua
reminder = {
	enabled = true,
	ignore_key = "<leader>i",
	toggle_key = "<leader>I",
	notify = print,
	numbers = false, -- highlight line or line numbers
},
```

</details>

<details><summary>scrollbar_marks</summary>

```lua
scrollbar_marks = {
	enabled = true,
},
```

</details>

<details><summary>surround</summary>

```lua
surround = {
	enabled = true,
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
```

</details>

<details><summary>hipatterns</summary>

```lua
hipatterns = {
	enabled = true,
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
```

</details>

<details><summary>scrollbar_todo</summary>

```lua
scrollbar_todo = {
	enabled = true,
},
```

</details>

<details><summary>nolint</summary>

```lua
nolint = {
	enabled = true,
	key = "gcs",
},
```

</details>

<details><summary>inlay</summary>

```lua
inlay = {
	enabled = true,
	key = "<leader>hI",
},
```

</details>

<details><summary>templates</summary>

```lua
templates = {
	enabled = true,
	templates_dir = vim.fn.stdpath("config") .. "/templates",
},
```

</details>

<details><summary>toggle</summary>

```lua
toggle = {
	enabled = true,
	mapping = {
		["true"] = "false",
		["false"] = "true",
		["on"] = "off",
		["off"] = "on",
		["yes"] = "no",
		["no"] = "yes",
	},
},
```

</details>

<details><summary>ufo_folds</summary>

```lua
ufo_folds = {
	enabled = true,
	-- in "kevinhwang91/nvim-ufo" opts
	-- fold_virt_text_handler = require("nvim-plugins.ufo_folds").fold_virt_text_handler,
},
```

</details>

<details><summary>badchars</summary>

```lua
badchars = {
	enabled = true,
	hl = "SpellBad",
	-- add = { [[\u2014]] }, -- (em dash)
},
```

</details>

<details><summary>simple_todo</summary>

```lua
simple_todo = {
	enabled = true,
	keymap = "<leader><Tab>",
	filepath = "~/TODO.md",
},
```

</details>

<details><summary>reviews</summary>

```lua
reviews = {
	view_key = "<leader>K",
	refresh_key = "<leader>Rr",
	enabled = true,
	interval = 1800, -- 30 minutes
	debug = false,
	highlight = nil, -- can be a hex string e.g. "#7E98E8"
	integrations = {
		scrollbar = false,
	},
},
```

</details>

<details><summary>breadcrumbs</summary>

```lua
breadcrumbs = {
	enabled = true,
	dark_color = "#606079",
	light_color = "#e0a363",
	max = 200,
	max_moves = 2000,
	decay_rate = 0.999,
},
```

</details>

<details><summary>auto_commit</summary>

```lua
auto_commit = {
	enabled = true,
	keymap = "<leader>commit",
	message = function()
		return "auto: " .. os.date("%H:%M:%S")
	end,
},
```

</details>

<details><summary>typst_preview</summary>

```lua
typst_preview = {
	enabled = true,
	key = "<leader>pt",
	left = "<Left>",
	right = "<Right>",
},
```

</details>

<details><summary>fff</summary>

```lua
fff = {
	enabled = true,
	key = "<leader><leader>",
},
```

</details>

<details><summary>oil_git</summary>

```lua
oil_git = {
	enabled = true,
	refresh_key = "<leader>Ro",
	highlight = {
		OilGitAdded = { fg = "#7fa563" },
		OilGitModified = { fg = "#f3be7c" },
		OilGitDeleted = { fg = "#d8647e" },
		OilGitRenamed = { fg = "#cba6f7" },
		OilGitUntracked = { fg = "#c48282" },
	},
},
```

</details>
