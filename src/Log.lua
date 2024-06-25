local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

local function format(...): string
	local args = ''

	for _, arg in ipairs({ ... }) do
		args ..= ' ' .. Util.stringify(arg)
	end

	return args
end

local Log = {
	Level = {
		Off = 0,
		Error = 1,
		Warn = 2,
		Info = 3,
		Debug = 4,
		Trace = 5,
	},
	__level = 2,
}

function Log.__setLevel(level: string)
	local num = Log.Level[level]

	if not num then
		Log.error('Invalid log level:', level)
	end

	Log.__level = num
end

function Log.trace(...)
	if Log.__level >= Log.Level.Trace then
		print('TRACE:' .. format(...))
	end
end

function Log.debug(...)
	if Log.__level >= Log.Level.Debug then
		print('DEBUG:' .. format(...))
	end
end

function Log.info(...)
	if Log.__level >= Log.Level.Info then
		print('INFO:' .. format(...))
	end
end

function Log.warn(...)
	if Log.__level >= Log.Level.Warn then
		warn('WARN:' .. format(...))
	end
end

function Log.error(...)
	if Log.__level >= Log.Level.Error then
		error('ERROR:' .. format(...), 0)
	end
end

return Log
