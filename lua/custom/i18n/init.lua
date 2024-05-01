local utils = require "custom.i18n.utils"
local log = require "custom.i18n.log"
local resolver = require "custom.i18n.translation_resolve"

local bufnr_ns_table = {}

vim.api.nvim_create_autocmd("BufEnter", { -- other events: BufEnter, BufWritePost, InsertLeave
	-- this creates a group for auto commands
	group = vim.api.nvim_create_augroup("I18n", {}),
	pattern = { "*.js", "*.ts", "*.tsx", "*.jsx" },

	callback = function(ev)
		log.infof("attaching I18n to buffer '%s'", ev.buf)

		-- todo only attach on specific file types
		-- todo only attach when package.json is using i18n / or config says so?

		vim.keymap.set("n", "<leader>is", ":I18n<CR>", { buffer = true, desc = "i18n: translate inline" })
		vim.keymap.set("n", "<leader>ic", ":I18nClear<CR>", { buffer = true, desc = "i18n: clear translations" })
		-- vim.api.nvim_command("I18n")

		-- setup things that are only available in that buffer
	end,
})

-- TODO: should we remove something on BufLeave?

vim.api.nvim_create_user_command('I18nClear', function()
	local bufnr = vim.api.nvim_get_current_buf()
	local ns_id = bufnr_ns_table[bufnr]
	if ns_id then
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	end
end, {})

vim.api.nvim_create_user_command('I18n', function(o)
	log.debugf("options: %s", vim.inspect(o))
	local bufnr = vim.api.nvim_get_current_buf()
	log.debugf('bufnr: %d', bufnr)

	local ltree = vim.treesitter.get_parser(bufnr)
	local stree = ltree:parse()
	local root = stree[1]:root()
	log.debugf('current buffer language: %s', ltree:lang())

	if not vim.tbl_contains({ "javascript", "typescript", "tsx", "jsx" }, ltree:lang()) then
		log.infof("not a supported language '%s'", ltree:lang())
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
		log.debugf("clearing namespace '%s' on buffer '%s'", ns_id, bufnr)
		vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
	else
		ns_id = vim.api.nvim_create_namespace('i18n')
		log.debugf("creating namespace '%s'", ns_id)
		bufnr_ns_table[bufnr] = ns_id
	end

	for _, node in ipairs(t_nodes) do
		-- local func = node[1]
		local args = node[2]
		local srow, scol = args:range()

		utils.highlight(bufnr, ns_id, args)

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
