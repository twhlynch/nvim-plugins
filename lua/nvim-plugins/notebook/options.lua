-- stylua: ignore
return {
	keybind_prefix = "<leader>c",
	max_output_lines = 10,
	custom_plot_theme = true,
	custom_theme_colors = { '#4878CF', '#6ACC65', '#D65F5F', '#B47CC7', '#C4AD66', '#77BEDB' },
	cell_gap = 0,
	debug = false,

	keys = {
		run_cell           = "r",
		run_cells_all      = "a",
		run_cells_up       = "u",
		run_cells_down     = "d",

		next_cell          = "]c",
		previous_cell      = "[c",

		insert_markdown    = "m",
		insert_code        = "c",
		split_cell         = "s",
		remove_cell        = "X",

		clear_all_output   = "x",
		refresh_all_output = "R",

		open_image         = "gx",
		show_output        = "<CR>",
		dump_images        = "D",
	},

	hl = {
		output  = "NonText",
		error   = "DiagnosticError",
		hint    = "DiagnosticHint",
		success = "DiagnosticOk",
	},

	strings = {
		new_cell      = { "# " },
		new_code_cell = { "# " },

		output_border    = "┃   ",
		cell_border      = "─",
		cell_executed    = "[ ✓ Done ]",
		cell_running     = "[ Running... ]",
		truncated_output = "<Enter> %s more lines",
		image_output     = "<gx> %s × image",

		bridge_error    = "Jupyter Bridge Error: ",
		install_prompt  = "Missing 'jupyter_client'. Install with pip?",
		no_client       = "Not running client",
		installing      = "Installing jupyter_client...",
		install_success = "Successfully installed",
		install_fail    = "Failed to install",
		no_venv         = "Not using a virtual environment",
		saved_images    = "Saved %d images",
		images_prompt   = "Dump images to working directory?",

		run_cell_desc           = "Run current cell",
		run_cells_all_desc      = "Run all cells",
		run_cells_up_desc       = "Run all cells above",
		run_cells_down_desc     = "Run all cells below",
		next_cell_desc          = "Next cell",
		previous_cell_desc      = "Prev cell",
		insert_markdown_desc    = "Insert markdown cell below",
		insert_code_desc        = "Insert code cell below",
		split_cell_desc         = "Split current cell",
		remove_cell_desc        = "Remove current cell",
		clear_all_output_desc   = "Clear all cell output",
		refresh_all_output_desc = "Rerender output",
		open_image_desc         = "Open current cell images",
		show_output_desc        = "Open current cell output",
		dump_images_desc        = "Dump all image output to /figures",
	},
}
