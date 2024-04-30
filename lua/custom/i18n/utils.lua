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

local function is_table(t)
	return type(t) == 'table'
end

local function merge_tables(t1, t2)
	for k, v in pairs(t2) do
		t1[k] = v
	end
	return t1
end

local function _flat_json(json, prefix)
	local result = {}

	for k, v in pairs(json) do
		if is_table(v) then
			result = merge_tables(result, _flat_json(v, prefix .. k .. "."))
		else
			result[prefix .. k] = v
		end
	end

	return result
end

--- Flattens a JSON object of translations.
--- @param json table
local function flat_json(json)
	return _flat_json(json, "")
end

return {
	log = log,
	highlight = highlight,
	is_table = is_table,
	merge_tables = merge_tables,
	flat_json = flat_json,
}
