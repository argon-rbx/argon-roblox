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
	get: (self: Config, setting: Setting, level: Level?) -> any,
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

local CONFIGS = {
	Place = "ArgonConfigPlace_" .. game.PlaceId,
	Game = "ArgonConfigGame_" .. game.GameId,
	Global = "ArgonConfigGlobal",
}

local CONFIGS_ORDERED = {"Place", "Game", "Global"}

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

function Config:get(setting, level)
	-- print(`Requesting config "{setting}" with level \{{level}}`)
	-- print(`Current configs: `, self.__configs)
	local default = DEFAULTS[setting]

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	level = if type(level) == "number" then level elseif type(level) == "string" then table.find(CONFIGS_ORDERED, level) else 1
	for i = level, #CONFIGS_ORDERED do
		local levelName = CONFIGS_ORDERED[i]
		local config = self.__configs[levelName]
		-- print(`	Searching in level "{configName}"`)
		if config[setting] ~= nil then
			-- print(`		Found setting at level "{configName}" = \{{config[setting]}}`)
			return config[setting]
		end
	end

	-- warn(`	No setting was set for "{setting}" in any level, sending default = \{{default}}`)
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

	if default == nil then
		Log.error(`Setting '{setting}' does not exist!`)
	end

	local levelName
	if type(level) == "number" then
		levelName = CONFIGS_ORDERED[level]
	else
		levelName = level
		level = table.find(CONFIGS_ORDERED, level)
	end

	value = Util.cast(value, type(default))
	local prevValue = self:get(setting)
	local parentValue = self:get(setting, level + 1)

	self.__configs[levelName][setting] = if value ~= parentValue then value else nil

	if self.__callbacks[setting] and self:get(setting) ~= prevValue then
		for _, callback in self.__callbacks[setting] do
			callback(value)
		end
	end

	local config = self.__configs[levelName]

	if not next(config) then
		plugin:SetSetting(CONFIGS[levelName], nil)
	else
		plugin:SetSetting(CONFIGS[levelName], config)
	end
end

function Config:restoreDefaults(level)
	-- print(`Restoring defaults for level "{level}"`)
	self.__configs[level] = {}

	for setting, _ in self.__configs[level] do
		if self.__callbacks[setting] then
			-- print(`	Triggering callbacks for setting "{setting}"`)
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
