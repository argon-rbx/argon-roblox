local Config = {}
Config.__index = Config

function Config.load(): { string: any }
	return Config
end

function Config:Get(key: string): any
	return ''
end

function Config:Set(key: string, value: any) end

function Config:Save() end

return Config
