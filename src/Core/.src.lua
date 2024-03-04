local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Client = require(Argon.Client)
local Config = require(Argon.Config)
local Util = require(Argon.Util)

local Processor = require(script.Processor)
local Tree = require(script.Tree)
local Error = require(script.Error)

export type Status = 'Connected' | 'Disconnected' | 'Error'

local Core = {}
Core.__index = Core

function Core.new(host: string?, port: string?)
	local self = setmetatable({}, Core)

	self.project = nil
	self.status = 'Disconnected'

	self.client = Client.new(host or Config:get('host'), port or Config:get('port'))
	self.tree = Tree.new()
	self.processor = Processor.new(self.tree)

	self.promt = function(_message: string, options: { string }): string
		return options[1]
	end

	self.statusChanged = function(_status: Status) end

	return self
end

function Core:init(): Promise.TypedPromise<nil>
	return Promise.new(function(resolve, reject)
		local project = self.client:fetchDetails():expect()
		local promptOptions = {
			'Continue',
			'Cancel',
		}

		if project.gameId and project.gameId ~= game.GameId then
			local err = Error.new(Error.GameId, game.GameId, project.gameId)

			if self.prompt(err.message, promptOptions) == 'Cancel' then
				return reject(err)
			end
		end

		if project.placeIds and not table.find(project.placeIds, game.PlaceId) then
			local err = Error.new(Error.PlaceIds, game.PlaceId, Util.arrayToString(project.placeIds))

			if self.prompt(err.message, promptOptions) == 'Cancel' then
				return reject(err)
			end
		end

		self.client:subscribe():expect()
		self.project = project

		local initialChanges = self.client:readAll():expect()

		self.processor:initialize(initialChanges)

		self:setStatus('Connected')

		return resolve()
	end)
end

function Core:stop()
	self.client:unsubscribe()
	self:setStatus('Disconnected')
end

function Core:setStatus(status: Status)
	self.status = status
	self.statusChanged(status)
end

function Core:setPromptHandler(prompt: (string, { string }) -> string)
	self.prompt = prompt
end

function Core:setStatusChangeHandler(statusChanged: (Status) -> ())
	self.statusChanged = statusChanged
end

return Core
