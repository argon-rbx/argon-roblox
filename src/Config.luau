local plugin = script:FindFirstAncestorWhichIsA("Plugin")

local Argon = script:FindFirstAncestor("Argon")

local Util = require(Argon.Util)
local Log = require(Argon.Log)

export type Level = "Place" | "Game" | "Global"
export type Setting =
	"InitialSyncPriority"
	| "Host"
	| "Port"
	| "AutoConnect"
	| "AutoReconnect"
	| "LiveHydrate"
	| "KeepUnknowns"
	| "TwoWaySync"
	| "SyncbackProperties"
	| "OnlyCodeMode"
	| "OpenInEditor"
	| "DisplayPrompts"
	| "ChangesThreshold"
	| "LogLevel"
	| "OverridePackages"

type Config = {
	__configs: { [Level]: { [Setting]: any } },
	__callbacks: { [Setting]: { (value: any) -> () } },
	load: () -> (),
	get: (self: Config, setting: Setting, level: Level?, exact: boolean?) -> any,
	getDefault: (self: Config, setting: Setting) -> any,
	set: (self: Config, setting: Setting, value: any, level: Level) -> (),
	restoreDefaults: (self: Config, level: Level) -> (),
	onChanged: (self: Config, setting: Setting, callback: (value: any) -> ()) -> () -> (),
}

local DEFAULTS = {
	InitialSyncPriority = "Server",
	Host = "localhost",
	Port = 8000,
	AutoConnect = true,
	AutoReconnect = false,
	LiveHydrate = true,
	KeepUnknowns = false,
	TwoWaySync = false,
	SyncbackProperties = false,
	OnlyCodeMode = true,
	OpenInEditor = false,
	DisplayPrompts = "Always",
	ChangesThreshold = 5,
	LogLevel = "Warn",
	OverridePackages = true,
}

local CONFIGS_ORDERED = { "Place", "Game", "Global" }
local CONFIGS = {
	Place = "ArgonConfigPlace_" .. game.PlaceId,
	Game = "ArgonConfigGame_" .. game.GameId,
	Global = "ArgonConfigGlobal",
}

local Config: Config = {
	__configs = {},
	__callbacks = {},
} :: Config

function Config.load()
	for level, config in CONFIGS do
		config = plugin:GetSetting(config)

		if config and type(config) == "table" then
			Config.__configs[level] = config
		else
			Config.__configs[level] = {}
		end
	end
end

function Config:get(setting, level, exact)
	local default = DEFAULTS[setting]
	local relevant = not level

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	if exact then
		return self.__configs[level][setting]
	end

	if level and level ~= "Global" then
		local index = table.find(CONFIGS_ORDERED, level)

		if not index then
			Log.error(`Config level '{level}' does not exist!`)
		end

		level = CONFIGS_ORDERED[index + 1]
	end

	for _, config in CONFIGS_ORDERED do
		if not relevant then
			if config == level then
				relevant = true
			else
				continue
			end
		end

		local value = self.__configs[config][setting]

		if value ~= nil then
			return value
		end
	end

	return default
end

function Config:getDefault(setting)
	local default = DEFAULTS[setting]

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	return default
end

function Config:set(setting, value, level)
	local default = DEFAULTS[setting]
	local config = self.__configs[level]

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	if value == config[setting] then
		return
	end

	value = Util.cast(value, type(default))
	config[setting] = if value == default then nil else value

	if self.__callbacks[setting] then
		for _, callback in self.__callbacks[setting] do
			callback(self:get(setting))
		end
	end

	if not next(config) then
		plugin:SetSetting(CONFIGS[level], nil)
	else
		plugin:SetSetting(CONFIGS[level], config)
	end
end

function Config:restoreDefaults(level)
	self.__configs[level] = {}

	for setting, _ in self.__configs[level] do
		if self.__callbacks[setting] then
			for _, callback in self.__callbacks[setting] do
				callback(self:getDefault(setting))
			end
		end
	end

	plugin:SetSetting(CONFIGS[level], nil)
end

function Config:onChanged(setting, callback)
	if not self.__callbacks[setting] then
		self.__callbacks[setting] = {}
	end

	local id = Util.generateGUID()
	self.__callbacks[setting][id] = callback

	return function()
		self.__callbacks[setting][id] = nil
	end
end

return Config
