local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Util = require(Argon.Util)
local Config = require(Argon.Config)

local Http = require(script.Http)
local Error = require(script.Error)
local generateId = require(script.generateId)

local Client = {}

function Client.new()
	local self = setmetatable({}, { __index = Client })

	self.isConnected = false
	self.clientId = generateId()
	self.host = Config:get('host')
	self.port = Config:get('port')

	return self
end

function Client:getUrl(): string
	return `http://{self.host}:{self.port}/`
end

function Client:fetchDetails(): Promise.Promise
	local url = self:getUrl() .. 'details'

	return Http.get(url):andThen(function(response)
		return response:json()
	end)
end

function Client:subscribe(): Promise.Promise
	local url = self:getUrl() .. 'subscribe'

	return Http.post(url, {
		clientId = self.clientId,
	})
		:andThen(function()
			self.isConnected = true
		end)
		:catch(function()
			return Promise.reject(Error.new(Error.AlreadySubscribed, self.clientId))
		end)
end

function Client:unsubscribe(): Promise.Promise
	local url = self:getUrl() .. 'unsubscribe'

	return Http.post(url, {
		clientId = self.clientId,
	})
		:andThen(function()
			self.isConnected = false
		end)
		:catch(function()
			return Promise.reject(Error.new(Error.NotSubscribed, self.clientId))
		end)
end

function Client:read(): Promise.Promise
	local url = self:getUrl() .. `read?clientId={self.clientId}`

	return Http.get(url):andThen(function(response)
		return response:json().queue
	end)
end

function Client:readAll(): Promise.Promise
	local url = self:getUrl() .. `readAll?clientId={self.clientId}`

	return Http.get(url):andThen(function()
		local queue = {}

		while true do
			local chunk = self:read():expect()

			if #chunk == 0 then
				break
			end

			Util.join(queue, chunk)
		end

		return queue
	end)
end

function Client:setHost(host: string)
	self.host = host
end

function Client:setPort(port: number)
	self.port = port
end

return Client
