local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

export type Level = 'Place' | 'Game' | 'Global'

local CONFIGS = {
	Place = 'ArgonConfigPlace_' .. game.PlaceId,
	Game = 'ArgonConfigGame_' .. game.GameId,
	Global = 'ArgonConfigGlobal',
}

local Config = {
	DEFAULTS = {
		host = 'localhost',
		port = 8000,
		autoConnect = true,
		openInEditor = false,
		twoWaySync = false,
	},
	configs = {},
}

function Config.load()
	for level, key in pairs(CONFIGS) do
		local config = plugin:GetSetting(key)

		if config and type(config) == 'table' then
			Config.configs[level] = config
		else
			Config.configs[level] = {}
		end
	end
end

function Config:get(key: string, level: Level?): any
	local default = self.DEFAULTS[key]

	if default == nil then
		error(`Setting '{key}' does not exist!`)
	end

	if level then
		return self.configs[level][key]
	end

	for _, config in pairs(self.configs) do
		if config[key] ~= nil then
			return config[key]
		end
	end

	return default
end

function Config:getDefault(key: string): any
	local default = self.DEFAULTS[key]

	if default == nil then
		error(`Setting '{key}' does not exist!`)
	end

	return default
end

function Config:set(key: string, value: any, level: Level)
	local default = self.DEFAULTS[key]

	if default == nil then
		error(`Setting '{key}' does not exist!`)
	end

	value = Util.cast(value, type(default))

	if value == default then
		self.configs[level][key] = nil
	else
		self.configs[level][key] = value
	end

	local config = self.configs[level]

	if Util.len(config) == 0 then
		plugin:SetSetting(CONFIGS[level], nil)
	else
		plugin:SetSetting(CONFIGS[level], config)
	end
end

function Config:restoreDefaults(level: Level)
	self.configs[level] = {}
	plugin:SetSetting(CONFIGS[level], nil)
end

return Config
