local utils = require "custom.i18n.utils"

---@return table<string, string>
local find_translation_files = function()
	---@type table<string, string>	
	local translation_files = {}

	local project_root = vim.fn.getcwd()

	-- TODO more logic etc.
	local translation_file = project_root .. "/src/locales/de.json"

	if vim.fn.filereadable(translation_file) == 1 then
		table.insert(translation_files, translation_file)
	end

	return translation_files
end

local function flat_json(j, prefix)
	local result = {}

	for k, v in pairs(j) do
		if utils.is_table(v) then
			flat_json(v, prefix .. k .. ".")
		else
			result[prefix .. k] = v
		end
	end

	return result
end

local function resolve_translation(key)
	utils.log("resolving translation: " .. key)

	local translation_files = find_translation_files()

	for _, translation_file in ipairs(translation_files) do
		utils.log("found translation: " .. translation_file)
		local r = vim.fn.json_decode(vim.fn.readfile(translation_file))

		local translations = flat_json(r, "")

		for k, v in pairs(translations) do
			utils.log(k .. " -> " .. v)
		end
	end


	return key
end

return {
	resolve_translation = resolve_translation,
}
