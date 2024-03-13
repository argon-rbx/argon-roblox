local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Client = require(Argon.Client)
local Config = require(Argon.Config)
local Log = require(Argon.Log)
local Executor = require(Argon.Executor)

local Processor = require(script.Processor)
local Tree = require(script.Tree)
local Error = require(script.Error)
local Types = require(script.Types)

local CHANGES_TRESHOLD = 10

local Core = {
	Status = {
		Disconnected = 0,
		Connecting = 1,
		Connected = 2,
	},
}
Core.__index = Core

function Core.new(host: string?, port: string?)
	local self = setmetatable({}, Core)

	self.project = nil
	self.state = 0

	self.client = Client.new(host or Config:get('Host'), port or Config:get('Port'))
	self.tree = Tree.new()
	self.processor = Processor.new(self.tree)
	self.executor = Executor.new()

	self.__prompt = function(_message: string, _changes: Types.Changes?): boolean
		return true
	end
	self.__ready = function(_project: Types.ProjectDetails) end
	self.__sync = function(_changes: Types.Changes) end

	return self
end

function Core:run(): Promise.TypedPromise<nil>
	return Promise.new(function(_, reject)
		self.state = Core.Status.Connecting

		local project = self.client:fetchDetails():expect()

		if project.gameId and project.gameId ~= game.GameId then
			local err = Error.new(Error.GameId, game.GameId, project.gameId)

			if not self.__prompt(err.message) or self.state ~= Core.Status.Connecting then
				return reject(err)
			end
		end

		if project.placeIds and not table.find(project.placeIds, game.PlaceId) then
			local err = Error.new(Error.PlaceIds, game.PlaceId, project.placeIds)

			if not self.__prompt(err.message) or self.state ~= Core.Status.Connecting then
				return reject(err)
			end
		end

		self.client:subscribe():expect()
		self.project = project

		local snapshot = self.client:getSnapshot():expect()
		local initialChanges = self.processor:initialize(snapshot)

		if self.state ~= Core.Status.Connecting then
			return reject(Error.new(Error.Terminated))
		end

		if initialChanges:total() > CHANGES_TRESHOLD then
			local err = Error.new(
				Error.TooManyChanges,
				#initialChanges.additions,
				#initialChanges.updates,
				#initialChanges.removals
			)

			if not self.__prompt(err.message, initialChanges) then
				return reject(err)
			end
		end

		self.processor:applyChanges(initialChanges)

		self.state = Core.Status.Connected
		self.__ready(project)

		return self:__startSyncLoop():expect()
	end)
end

function Core:stop()
	self.state = Core.Status.Disconnected

	if self.client.isSubscribed then
		self.client:unsubscribe():catch(function(err)
			Log.debug('Failed to unsubscribe from the server', err)
		end)
	end
end

function Core:onPrompt(callback: (message: string, changes: Types.Changes?) -> boolean)
	self.__prompt = callback
end

function Core:onReady(callback: (project: Types.ProjectDetails) -> ())
	self.__ready = callback
end

function Core:onSync(callback: (changes: Types.Changes) -> ())
	self.__sync = callback
end

function Core:__startSyncLoop()
	return Promise.new(function(resolve)
		while self.state == Core.Status.Connected do
			local message = self.client:read():expect()

			-- We disconnect from the server
			if not message then
				break
			end

			local event = next(message)
			local data = message[event]

			if event == 'SyncChanges' then
				self.processor:applyChanges(data)
				self.__sync(message)
			elseif event == 'SyncDetails' then
				print('SyncDetails') -- TODO
				self.__sync(message)
			elseif event == 'ExecuteCode' then
				self.executor:execute(data.code)
			else
				local err = Error.new(Error.UnknownEvent, event, data)
				Log.warn(err)
			end
		end

		resolve()
	end)
end

function Core.wasExitGraceful(err: Error.Error)
	return err == Error.GameId or err == Error.PlaceIds or err == Error.TooManyChanges or err == Error.Terminated
end

return Core
