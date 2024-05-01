local utils = require "custom.i18n.utils"
local log = require "custom.i18n.log"

---@class TranslationFiles
---@field buffers table<string, buffer>
local translation_files = {
	buffers = {},
}

function translation_files:contains(name)
	for v, _ in pairs(self.buffers) do
		if v == name then
			return true
		end
	end

	return false
end

function translation_files:add_buffer(file_path, buf)
	self.buffers[file_path] = buf
	-- vim.api.nvim_buf_attach(buf, false, {
	-- 	on_lines = function()
	-- 		log.debugf("buffer '%s' changed", buf)
	-- 	end,
	-- 	on_detach = function()
	-- 		log.debugf("buffer '%s' detached", buf)
	-- 		self.buffers[buf] = nil
	-- 	end,
	-- })
end

function translation_files:add(file_path)
	if self:contains(file_path) then
		log.debugf("translation file '%s' already exists", file_path)
		return
	end

	log.debugf("adding translation file '%s'", file_path)

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_get_name(buf) == file_path then
			if vim.api.nvim_buf_is_loaded(buf) then
				log.debugf("buffer for file '%s' already exists and is loaded", file_path)
			else
				log.debugf("buffer for file '%s' already exists and is not loaded", file_path)
			end

			self:add_buffer(file_path, buf)
			return
		end
	end

	if vim.fn.filereadable(file_path) == 0 then
		log.errorf("file '%s' does not exist", file_path)
		return
	end

	local buf = vim.fn.bufadd(file_path)
	self:add_buffer(file_path, buf)
end

---@return table<string, buffer>
local find_translation_files = function()
	local project_root = vim.fn.getcwd()

	-- TODO resolve this maybe from the .vscode/settings.json and other config files
	local translations_root = project_root .. "/src/locales"
	local files = utils.find_json_files_recursives(translations_root)

	-- TODO need caching
	-- How do we know if the file has changed?
	for translation_file, _ in pairs(files) do
		translation_files:add(translation_file)
	end

	return translation_files.buffers
end

---Resolves a translation key to a translation string.
---@param key string
---@return string
local function resolve_translation(key)
	log.debugf("resolving translation key '%s'", key)

	local files = find_translation_files()

	for file, _ in pairs(files) do
		local r = vim.fn.json_decode(vim.fn.readfile(file))
		local translations = utils.flat_json(r)

		for k, v in pairs(translations) do
			if k == key then
				return v
			end
		end
	end

	return key
end

return {
	resolve_translation = resolve_translation,
}
