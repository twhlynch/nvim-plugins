-- options

---@class Opts plugin config options
---@field keybind? string keybind to run the task at the cursor line
---@field sign_icon? string icon to show as the task indicator
---@field sign_hl? string hl group to color the task indicator

-- state

---@class PluginState global state
---@field project_tasks table<string, TaskConfig>
---@field project_inputs table<string, UserInput>

-- aliases

---@alias command string | string[]
---@alias env table<string, string>

-- vscode configs

---@class TaskOptions vscode task options
---@field env? env map of env variable name to value that will exist for the task
---@field cwd? string working directory for the task to run in

---@class TaskConfig vscode task
---@field label? string unique name for a task
---@field type? "shell" | "process" | "npm" is the task a shell command or a process or other
---@field command? string command to run
---@field args? string[] args to pass to the command
---@field options? TaskOptions extra task options
---@field group? string | Group group info
---@field script? string script for npm tasks

---@class Group task group info
---@field kind string group name
---@field isDefault boolean if the task is the default for the group

---@class UserInput vscode task input
---@field id? string unique id for input
---@field type? "promptString" input type
---@field description? string prompt to show for the input
---@field default? string default value for the input

---@class LaunchConfig vscode launch config
---@field name? string unique name for launch config
---@field type? "node" | "python" | "debugpy" | "cppdbg" | "extensionHost" type of config
---@field request? "launch" | "attach" request type of config
---@field program? string absolute path to the program
---@field runtimeExecutable? string absolute path to the program
---@field args? string[] args to pass to the command
---@field preLaunchTask? string config id to run first
---@field cwd? string working directory for the config to run in
---@field env? env map of env variable name to value that will exist for the config

---@class TasksJson tasks.json file schema
---@field version? string schema version
---@field tasks? TaskConfig[] list of task congifs
---@field inputs? UserInput[] list of inputs

---@class LaunchJson launch.json file schema
---@field version? string version of schema
---@field configurations? LaunchConfig[] list of launch configs
---@field inputs? UserInput[] list of inputs
