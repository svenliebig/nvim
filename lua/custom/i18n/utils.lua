local function log(message)
	local logfile = vim.fn.expand('~/.local/state/nvim/svenliebig.log') -- Change the path as needed
	local timestamp = os.date('%Y-%m-%d %H:%M:%S')
	local logline = string.format("[%s] %s\n", timestamp, message)
	local file = io.open(logfile, 'a') -- 'a' opens the file for appending
	if file then
		file:write(logline)
		file:close()
	else
		print("Error opening log file")
	end
end

--- @param bufnr buffer
--- @param ns_id number
--- @param node TSNode
local function highlight(bufnr, ns_id, node)
	local line, start, _, end_ = node:range()
	local used_ns_id = vim.api.nvim_buf_add_highlight(bufnr, ns_id, 'LspReferenceText', line, start, end_)
	log("use the following ns id to highlight: " .. used_ns_id)
end

return {
	log = log,
	highlight = highlight,
}
