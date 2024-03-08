local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Client = require(Argon.Client)
local Config = require(Argon.Config)
local Log = require(Argon.Log)

local Processor = require(script.Processor)
local Tree = require(script.Tree)
local Error = require(script.Error)

export type Status = number

local CHANGES_TRESHOLD = 10

local Core = {}
Core.__index = Core

Core.Status = {
	Disconnected = 0,
	Conntected = 1,
	Error = 2,
}

function Core.new(host: string?, port: string?)
	local self = setmetatable({}, Core)

	self.project = nil
	self.shouldSync = false
	self.status = Core.Status.Disconnected

	self.client = Client.new(host or Config:get('host'), port or Config:get('port'))
	self.tree = Tree.new()
	self.processor = Processor.new(self.tree)

	self.prompt = function(_message: string, options: { string }): string
		return options[1]
	end

	self.statusChanged = function(_status: Status) end

	return self
end

function Core:run(): Promise.TypedPromise<nil>
	return Promise.new(function(_, reject)
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
			local err = Error.new(Error.PlaceIds, game.PlaceId, project.placeIds)

			if self.prompt(err.message, promptOptions) == 'Cancel' then
				return reject(err)
			end
		end

		self.client:subscribe():expect()
		self.project = project

		local snapshot = self.client:getSnapshot():expect()
		local initialChanges = self.processor:initialize(snapshot)

		if initialChanges:total() > CHANGES_TRESHOLD then
			local err = Error.new(
				Error.TooManyChanges,
				#initialChanges.additions,
				#initialChanges.updates,
				#initialChanges.removals
			)

			if self.prompt(err.message, promptOptions) == 'Cancel' then
				return reject(err)
			end
		end

		for _, addition in ipairs(initialChanges.additions) do
			self.processor:applyAddition(addition)
		end

		for _, update in ipairs(initialChanges.updates) do
			self.processor:applyUpdate(update)
		end

		for _, removal in ipairs(initialChanges.removals) do
			self.processor:applyRemoval(removal)
		end

		self:setStatus(Core.Status.Conntected)

		return self:__startSyncLoop():expect()
	end)
end

function Core:stop()
	self.client:unsubscribe()
	self:setStatus(Core.Status.Disconnected)
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

function Core:__startSyncLoop()
	return Promise.new(function(resolve)
		while self.status == Core.Status.Conntected do
			local queue = self.client:read():expect()

			for _, message in ipairs(queue) do
				local event = next(message)
				local data = message[event]

				if event == 'Add' then
					self.processor:applyAddition(data)
				elseif event == 'Update' then
					self.processor:applyUpdate(data)
				elseif event == 'Remove' then
					self.processor:applyRemoval(data)
				else
					local err = Error.new(Error.UnknownEvent, event, data)
					Log.warn(err)
				end
			end

			task.wait(Config:get('syncInterval'))
		end

		resolve()
	end)
end

return Core
