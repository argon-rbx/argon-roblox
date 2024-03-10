local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

export type Level = 'Place' | 'Game' | 'Global'
export type Setting =
	'Host'
	| 'Port'
	| 'AutoConnect'
	| 'OpenInEditor'
	| 'TwoWaySync'
	| 'TwoWaySyncProperties'
	| 'LogLevel'
	| 'SyncInterval'

local CONFIGS = {
	Place = 'ArgonConfigPlace_' .. game.PlaceId,
	Game = 'ArgonConfigGame_' .. game.GameId,
	Global = 'ArgonConfigGlobal',
}

local Config = {
	DEFAULTS = {
		Host = 'localhost',
		Port = 8000,
		AutoConnect = true,
		OpenInEditor = false,
		TwoWaySync = false,
		TwoWaySyncProperties = false,
		LogLevel = 'Warn',
		SyncInterval = 0.2,
	},
	__configs = {},
}

function Config.load()
	for level, config in pairs(CONFIGS) do
		config = plugin:GetSetting(config)

		if config and type(config) == 'table' then
			Config.__configs[level] = config
		else
			Config.__configs[level] = {}
		end
	end
end

function Config:get(setting: Setting, level: Level?): any
	local default = self.DEFAULTS[setting]

	if default == nil then
		error(`Setting '{setting}' does not exist!`)
	end

	if level then
		return self.__configs[level][setting]
	end

	for _, config in pairs(self.__configs) do
		if config[setting] ~= nil then
			return config[setting]
		end
	end

	return default
end

function Config:getDefault(settings: Setting): any
	local default = self.DEFAULTS[settings]

	if default == nil then
		error(`Setting '{settings}' does not exist!`)
	end

	return default
end

function Config:set(setting: Setting, value: any, level: Level)
	local default = self.DEFAULTS[setting]

	if default == nil then
		error(`Setting '{setting}' does not exist!`)
	end

	value = Util.cast(value, type(default))

	if value == default then
		self.__configs[level][setting] = nil
	else
		self.__configs[level][setting] = value
	end

	local config = self.__configs[level]

	if Util.len(config) == 0 then
		plugin:SetSetting(CONFIGS[level], nil)
	else
		plugin:SetSetting(CONFIGS[level], config)
	end
end

function Config:restoreDefaults(level: Level)
	self.__configs[level] = {}
	plugin:SetSetting(CONFIGS[level], nil)
end

return Config
