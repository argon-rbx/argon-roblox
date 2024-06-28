local Config = require(script.Config)
local Log = require(script.Log)
local App = require(script.App)

Config.load()
Log.__setLevel(Config:get('LogLevel'))
App.new()

Config:onChanged('LogLevel', function(level)
	Log.__setLevel(level)
end)
