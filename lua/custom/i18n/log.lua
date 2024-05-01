local os = require('os')

local logfile = vim.fn.expand('~/.local/state/nvim/i18n.log')
local loglevel = os.getenv('NVIM_I18N_LOGLEVEL') or 'debug'

local function loglevel_to_number(level)
	if level == 'debug' then
		return 0
	elseif level == 'info' then
		return 1
	elseif level == 'warn' then
		return 2
	elseif level == 'error' then
		return 3
	else
		return 1
	end
end

local loglevel_number = loglevel_to_number(loglevel)

local function should_log(level)
	return loglevel_to_number(level) >= loglevel_number
end

local function log(message)
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

local function debug(message)
	if should_log('debug') then
		log(string.format("[DEBUG] %s", message))
	end
end

local function debugf(message, ...)
	if should_log('debug') then
		debug(string.format(message, ...))
	end
end

local function info(message)
	if should_log('info') then
		log(string.format("[INFO] %s", message))
	end
end

local function warn(message)
	if should_log('warn') then
		log(string.format("[WARN] %s", message))
	end
end

local function error(message)
	if should_log('error') then
		log(string.format("[ERROR] %s", message))
	end
end

return {
	log = log,
	debug = debug,
	debugf = debugf,
	info = info,
	warn = warn,
	error = error,
}
