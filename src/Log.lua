local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

local function format(...): string
	local args = ''

	for arg in ipairs({ ... }) do
		if type(arg) == 'table' and arg.messsage then
			args ..= ' ' .. arg.message
		else
			args ..= ' ' .. Util.stringify(arg)
		end
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
	__current = 2,
}

function Log.trace(...)
	if Log.__current >= Log.Level.Trace then
		print('TRACE:' .. format(...))
	end
end

function Log.debug(...)
	if Log.__current >= Log.Level.Debug then
		print('DEBUG:' .. format(...))
	end
end

function Log.info(...)
	if Log.__current >= Log.Level.Info then
		print('INFO:' .. format(...))
	end
end

function Log.warn(...)
	if Log.__current >= Log.Level.Warn then
		warn('WARN:', format(...))
	end
end

function Log.error(...)
	if Log.__current >= Log.Level.Error then
		error('ERROR:' .. format(...), 0)
	end
end

return Log
