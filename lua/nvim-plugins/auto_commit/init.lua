local M = {}

local options = {
	keymap = "<leader>commit",
	message = function()
		return "auto: " .. os.date("%H:%M:%S")
	end,
}

local enabled = false

local function is_git_repo()
	local result = vim.fn.systemlist("git rev-parse --is-inside-work-tree")
	return result[1] == "true"
end

local function commit()
	-- save
	vim.cmd("write")

	-- check status
	local status = vim.fn.systemlist("git status --porcelain")
	if #status == 0 then
		return
	end

	-- add
	vim.fn.system("git add " .. vim.fn.expand("%"))

	-- commit
	local msg = options.message()
	vim.fn.system("git commit -m '" .. msg .. "'")
end

function M.toggle()
	-- check repo
	if not is_git_repo() then
		vim.notify("Not a git repo")
		return
	end

	-- toggle
	enabled = not enabled

	if enabled then
		-- enable
		vim.api.nvim_create_autocmd("InsertLeave", {
			group = M.augroup,
			callback = function()
				if vim.bo.modified then
					commit()
				end
			end,
		})
	else
		-- disable
		vim.api.nvim_clear_autocmds({ group = M.augroup })
	end

	-- notify
	vim.notify("Auto Commit " .. (enabled and "enabled" or "disabled"))
end

function M.setup(opts)
	options = vim.tbl_deep_extend("keep", opts or {}, options)

	M.augroup = vim.api.nvim_create_augroup("AutoCommit", { clear = true })

	vim.keymap.set("n", options.keymap, M.toggle, { desc = "Toggle Auto Commit" })
end

return M
