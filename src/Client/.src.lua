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

function Client:subscribe(ignoreIds: boolean): Promise.Promise
	local url = self:getUrl() .. 'details'

	return Http.get(url):andThen(function(response)
		local details = response:json()

		if not ignoreIds then
			if details.gameId and details.gameId ~= game.GameId then
				return Promise.reject(Error.new(Error.GameId, game.GameId, details.gameId))
			end

			if details.placeIds and not table.find(details.placeIds, game.PlaceId) then
				return Promise.reject(Error.new(Error.PlaceIds, game.PlaceId, Util.arrayToString(details.placeIds)))
			end
		end

		local url = self:getUrl() .. 'subscribe'

		return Http.post(url, {
			clientId = self.clientId,
		})
			:andThen(function()
				self.isConnected = true
				return details
			end)
			:catch(function()
				return Promise.reject(Error.new(Error.AlreadySubscribed, self.clientId))
			end)
	end)
end

function Client:unsubscribe(): Promise.Promise
	local url = self:getUrl() .. 'unsubscribe'

	return Http.post(url, {
		clientId = self.clientId,
	}):andThen(function()
		self.isConnected = false
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
