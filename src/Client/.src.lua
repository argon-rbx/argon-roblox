local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Types = require(Argon.Core.Types)

local Http = require(script.Http)
local Error = require(script.Error)

local function generateId(): number
	return math.floor(math.random() * 10 ^ 10)
end

local Client = {}
Client.__index = Client

function Client.new(host: string, port: number)
	local self = setmetatable({}, Client)

	self.isSubscribed = false
	self.clientId = generateId()
	self.host = host
	self.port = port

	return self
end

function Client:getUrl(): string
	return `http://{self.host}:{self.port}/`
end

function Client:fetchDetails(): Promise.TypedPromise<Types.ProjectDetails>
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
			self.isSubscribed = true
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
			self.isSubscribed = false
		end)
		:catch(function()
			return Promise.reject(Error.new(Error.NotSubscribed, self.clientId))
		end)
end

function Client:read(): Promise.TypedPromise<Types.Changes>
	local url = self:getUrl() .. `read?clientId={self.clientId}`

	return Http.get(url):andThen(function(response)
		return response:json().queue
	end)
end

function Client:getSnapshot(): Promise.TypedPromise<Types.Changes>
	local url = self:getUrl() .. `snapshot?clientId={self.clientId}`

	return Http.get(url):andThen(function(response)
		return response:json()
	end)
end

return Client
