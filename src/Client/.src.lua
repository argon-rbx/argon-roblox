local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Types = require(Argon.Types)
local Place = require(Argon.Place)

local Http = require(script.Http)
local Error = require(script.Error)

local function generateId(): number
	return math.floor(math.random() * 10 ^ 9)
end

local Client = {}
Client.__index = Client

function Client.new(host: string, port: number)
	local self = setmetatable({}, Client)

	self.isSubscribed = false
	self.clientId = generateId()
	self.placeName = Place.Name
	self.host = host
	self.port = port

	return self
end

function Client:getUrl(): string
	return `http://{self.host}:{self.port}/`
end

function Client:fetchDetails(): Promise.TypedPromise<Types.Project>
	local url = self:getUrl() .. 'details'

	return Http.get(url):andThen(function(response)
		return response:decode()
	end)
end

function Client:subscribe(): Promise.Promise
	local url = self:getUrl() .. 'subscribe'

	return Http.post(url, {
		clientId = self.clientId,
		name = self.placeName,
	})
		:andThen(function()
			self.isSubscribed = true
		end)
		:catch(function(err)
			if err == Error.Unknown then
				return Promise.reject(Error.new(Error.AlreadySubscribed, self.clientId))
			else
				return Promise.reject(err)
			end
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
		:catch(function(err)
			if err == Error.Unknown then
				return Promise.reject(Error.new(Error.NotSubscribed, self.clientId))
			else
				return Promise.reject(err)
			end
		end)
end

function Client:getSnapshot(): Promise.TypedPromise<Types.Snapshot>
	local url = self:getUrl() .. 'snapshot'

	return Http.get(url):andThen(function(response)
		return response:decode()
	end)
end

function Client:read(): Promise.TypedPromise<Types.Message>
	local url = self:getUrl() .. `read?clientId={self.clientId}`

	return Http.get(url)
		:andThen(function(response)
			return response:decode()
		end)
		:catch(function(err)
			-- We no longer need this as Rust queue now uses `recv_timeout`
			if err == Error.Timedout then
				return self:read()
			else
				return Promise.reject(err)
			end
		end)
end

function Client:write(changes: Types.Changes): Promise.Promise
	local url = self:getUrl() .. `write`

	return Http.post(url, {
		clientId = self.clientId,
		changes = changes,
	})
end

function Client:open(instance: Types.Ref, line: number?): Promise.Promise
	local url = self:getUrl() .. 'open'

	return Http.post(url, {
		instance = type(instance) == 'string' and buffer.fromstring(instance) or instance,
		line = line or 1,
	})
end

return Client
