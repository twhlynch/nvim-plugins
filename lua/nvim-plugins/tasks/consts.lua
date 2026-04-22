return {
	tasks_version = "2.0.0",
	launch_version = "0.2.0",

	sign_name = "VSCodeTask",
	sign_group = "vscode_tasks",
	namespace_name = "tasks",

	strings = {
		task_failed = "Task failed with code %s",
		missing_command = "Config missing 'command'",
		missing_script = "Config missing 'script'",
		missing_program = "Config missing 'program' or 'runtimeExecutable'",
		task_not_found = "preLaunchTask '%s' not found in tasks.json",
		no_target = "No runnable target on this line",
		bad_version = "Version %s is not %s and may not be supported",
		no_default_build_task = "No default build task found",

		term_title = " VSCode Task Runner ",
		keybind_desc = "Run VSCode Task/Launch",
	},
}
