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
	| "Https"
	| "DiffLinesLimit"
	| "DisplayPrompts"
	| "ChangesThreshold"
	| "LogLevel"
	| "OverridePackages"

export type Source = Level | "Default"

type Config = {
	__configs: { [Level]: { [Setting]: any } },
	__callbacks: { [Setting]: { [string]: (value: any) -> () } },
	load: () -> (),
	get: (self: Config, setting: Setting, level: Level?, exact: boolean?) -> any,
	getDefault: (self: Config, setting: Setting) -> any,
	set: (self: Config, setting: Setting, value: any, level: Level) -> (),
	unset: (self: Config, setting: Setting, level: Level) -> (),
	isSet: (self: Config, setting: Setting, level: Level) -> boolean,
	resolve: (self: Config, setting: Setting, level: Level?) -> (any, Source, boolean),
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
	Https = false,
	DiffLinesLimit = 3000,
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

function Config:resolve(setting: Setting, level: Level?): (any, Source, boolean)
	local default = DEFAULTS[setting]

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	local startLevel: Level = level or "Place"
	local isExplicit = self.__configs[startLevel][setting] ~= nil

	local startIndex = table.find(CONFIGS_ORDERED, startLevel) or 1
	for i = startIndex, #CONFIGS_ORDERED do
		local lvl = CONFIGS_ORDERED[i]
		local val = self.__configs[lvl][setting]
		if val ~= nil then
			return val, lvl, isExplicit
		end
	end

	return default, "Default", isExplicit
end

function Config:isSet(setting: Setting, level: Level): boolean
	return self.__configs[level][setting] ~= nil
end

function Config:get(setting: Setting, level: Level?, exact: boolean?): any
	local default = DEFAULTS[setting]

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	if exact then
		return if level then self.__configs[level][setting] else nil
	end

	local val = self:resolve(setting, level)
	return val
end

function Config:getDefault(setting: Setting): any
	local default = DEFAULTS[setting]

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	return default
end

function Config:set(setting: Setting, value: any, level: Level)
	local default = DEFAULTS[setting]
	local config = self.__configs[level]

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	if value == config[setting] then
		return
	end

	value = Util.cast(value, type(default))
	config[setting] = value

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

function Config:unset(setting: Setting, level: Level)
	local config = self.__configs[level]

	if config[setting] == nil then
		return
	end

	config[setting] = nil

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

function Config:restoreDefaults(level: Level)
	local oldConfig = self.__configs[level]
	self.__configs[level] = {}

	for setting, _ in oldConfig do
		if self.__callbacks[setting] then
			for _, callback in self.__callbacks[setting] do
				callback(self:get(setting))
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
