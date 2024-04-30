local utils = require "custom.i18n.utils"
local resolver = require "custom.i18n.translation_resolve"

local bufnr_ns_table = {}

vim.api.nvim_create_user_command('I18n', function()
	local bufnr = vim.api.nvim_get_current_buf()
	utils.log('bufnr: ' .. bufnr)
	local ltree = vim.treesitter.get_parser(bufnr)
	local stree = ltree:parse()
	local root = stree[1]:root()
	utils.log('current buffer language: ' .. ltree:lang())

	if not vim.tbl_contains({ "javascript", "typescript", "tsx", "jsx" }, ltree:lang()) then
		utils.log("Not a supported language: " .. ltree:lang())
		return {}
	end

	local query = vim.treesitter.query.parse(ltree:lang(), [[
		(call_expression
			function: (identifier) @t_func (#eq? @t_func "t")
			arguments: (arguments
				(string
					(string_fragment) @str_frag
				)
			)
		)
		]]
	)

	---@type table<integer,TSNode[]>
	local t_nodes = {}

	for _, match in query:iter_matches(root, bufnr, 0, -1) do
		-- TODO  : Getting the function name might be useless
		local func = match[1]
		local args = match[2]
		table.insert(t_nodes, { func, args })
	end

	local ns_id = bufnr_ns_table[bufnr]
	if ns_id then
		utils.log(string.format("clearing namespace '%s' on buffer '%s'", ns_id, bufnr))
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	else
		ns_id = vim.api.nvim_create_namespace('svenliebig')
		utils.log("creating namespace: " .. ns_id)
		bufnr_ns_table[bufnr] = ns_id
	end

	for _, node in ipairs(t_nodes) do
		-- local func = node[1]
		local args = node[2]
		local srow, scol = args:range()

		utils.highlight(bufnr, ns_id, args)

		utils.log("highlighted: " .. args:range())

		local i18nkey = vim.treesitter.get_node_text(args, bufnr)
		local translation = resolver.resolve_translation(i18nkey)

		vim.api.nvim_buf_set_extmark(bufnr, ns_id, srow, scol, {
			virt_text = { { translation, "LspReferenceText" } },
			virt_text_pos = "eol",
		})

		-- vim.api.nvim_buf_set_extmark(bufnr, ns_id, srow, scol, {
		-- 	virt_text = { { "⚠️ ", "WarningMsg", } },
		-- 	virt_text_pos = "overlay",
		-- })
	end
end, {})
