local utils = require "custom.i18n.utils"

local function resolve_translation(key)
	utils.log("resolving translation: " .. key)
	return key
end

return {
	resolve_translation = resolve_translation,
}
