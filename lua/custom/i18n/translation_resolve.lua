local utils = require "custom.i18n.utils"

---@return table<string, string>
local find_translation_files = function()
	---@type table<string, string>	
	local translation_files = {}

	local project_root = vim.fn.getcwd()

	-- TODO more logic etc.
	local translations_root = project_root .. "/src/locales"

	local files = utils.find_json_files_recursives(translations_root)

	-- TODO need caching
	-- How do we know if the file has changed?
	--
	for translation_file, _ in pairs(files) do
		-- utils.log("found translation file: " .. translation_file)
		if vim.fn.filereadable(translation_file) == 1 then
			table.insert(translation_files, translation_file)
		end
	end

	return translation_files
end

---Resolves a translation key to a translation string.
---@param key string
---@return string
local function resolve_translation(key)
	-- utils.log("resolving translation: " .. key)

	local translation_files = find_translation_files()

	for _, translation_file in ipairs(translation_files) do
		-- utils.log("found translation: " .. translation_file)
		local r = vim.fn.json_decode(vim.fn.readfile(translation_file))

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
