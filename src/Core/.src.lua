local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Client = require(Argon.Client)
local Config = require(Argon.Config)
local Log = require(Argon.Log)

local Processor = require(script.Processor)
local Tree = require(script.Tree)
local Error = require(script.Error)
local Types = require(script.Types)

local CHANGES_TRESHOLD = 10

local Core = {}
Core.__index = Core

function Core.new(host: string?, port: string?)
	local self = setmetatable({}, Core)

	self.project = nil
	self.shouldSync = false
	self.isConnected = false

	self.client = Client.new(host or Config:get('Host'), port or Config:get('Port'))
	self.tree = Tree.new()
	self.processor = Processor.new(self.tree)

	self.__prompt = function(_message: string, _changes: Types.Changes?): boolean
		return true
	end
	self.__ready = function(_project: Types.ProjectDetails) end
	self.__sync = function(_changes: Types.Changes) end

	return self
end

function Core:run(): Promise.TypedPromise<nil>
	return Promise.new(function(_, reject)
		local project = self.client:fetchDetails():expect()

		if project.gameId and project.gameId ~= game.GameId then
			local err = Error.new(Error.GameId, game.GameId, project.gameId)

			if not self.__prompt(err.message) then
				return reject(err)
			end
		end

		if project.placeIds and not table.find(project.placeIds, game.PlaceId) then
			local err = Error.new(Error.PlaceIds, game.PlaceId, project.placeIds)

			if not self.__prompt(err.message) then
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

			if not self.__prompt(err.message, initialChanges) then
				return reject(err)
			end
		end

		self.processor:applyChanges(initialChanges)

		self.isConnected = true
		self.__ready(project)

		return self:__startSyncLoop():expect()
	end)
end

function Core:stop()
	self.isConnected = false

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
		while self.isConnected do
			local message = self.client:read():expect()

			-- We disconnect from the server
			if not message then
				break
			end

			local event = next(message)
			local data = message[event]

			if event == 'SyncChanges' then
				self.processor:applyChanges(data)
			elseif event == 'SyncDetails' then
				print('SyncDetails') -- TODO
			elseif event == 'ExecuteCode' then
				print('ExecuteCode') -- TODO
			else
				local err = Error.new(Error.UnknownEvent, event, data)
				Log.warn(err)
			end

			self.__sync(message)
		end

		resolve()
	end)
end

return Core
