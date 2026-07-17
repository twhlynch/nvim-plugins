local M = {}

local cached_dir = nil --- @type string | nil
--- @return string
function M.tempdir()
	if cached_dir then
		return cached_dir
	end

	cached_dir = vim.fn.tempname() .. "_typst_preview"
	vim.fn.mkdir(cached_dir, "p")

	return cached_dir
end

--- @param pdf string
--- @return integer
function M.count_pages(pdf)
	if vim.fn.executable("pdfinfo") ~= 1 then
		return 1
	end

	local info = vim.fn.systemlist({ "pdfinfo", pdf })
	for _, line in ipairs(info) do
		local n = line:match("^Pages:%s*(%d+)")
		if n then
			---@diagnostic disable-next-line: return-type-mismatch
			return tonumber(n)
		end
	end

	return 1
end

--- @param pdf string
--- @param page integer
--- @param dir string
--- @param gen integer
--- @return string | nil
function M.render_page(pdf, page, dir, gen)
	local path = dir .. "/g" .. gen .. "_p" .. page .. ".png"
	if vim.fn.filereadable(path) == 1 then
		return path
	end

	vim.fn.system({
		"magick",
		"-density",
		"192",
		pdf .. "[" .. (page - 1) .. "]",
		"-background",
		"white",
		"-alpha",
		"remove",
		path,
	})

	if vim.fn.filereadable(path) == 1 then
		return path
	end

	return nil
end

--- @param buf integer
--- @param width integer
--- @return integer
function M.create_preview_window(buf, width)
	local win = vim.api.nvim_open_win(buf, false, {
		split = "right",
		width = width,
	})

	vim.wo[win].wrap = false
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].foldcolumn = "0"
	vim.wo[win].winfixwidth = true

	return win
end

--- @return integer
function M.create_preview_buffer()
	local buf = vim.api.nvim_create_buf(false, true)

	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].swapfile = false
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "typst_preview"

	return buf
end

--- @param buf integer
--- @param src string
--- @param max_width integer
function M.attach_image(buf, src, max_width)
	local ok, image = pcall(require, "snacks.image.buf")
	if ok and image then
		image.attach(buf, { src = src, max_width = max_width })
	end
end

return M
