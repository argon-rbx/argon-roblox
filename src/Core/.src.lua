local ScriptEditorService = game:GetService('ScriptEditorService')

local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Client = require(Argon.Client)
local Config = require(Argon.Config)
local Log = require(Argon.Log)
local Util = require(Argon.Util)
local Types = require(Argon.Types)
local Watcher = require(Argon.Watcher)
local Executor = require(Argon.Executor)

local Initializer = require(script.Initializer)
local WriteProcessor = require(script.Processors.Write)
local ReadProcessor = require(script.Processors.Read)
local Tree = require(script.Tree)
local Error = require(script.Error)

local CHANGES_TRESHOLD = 5

local Core = {
	Status = {
		Disconnected = 0,
		Connecting = 1,
		Connected = 2,
		Disconnecting = 3,
	},
}
Core.__index = Core

function Core.new(host: string?, port: string?)
	local self = setmetatable({}, Core)

	self.project = nil
	self.rootDirs = {}
	self.connections = {}
	self.status = 0

	self.tree = Tree.new()
	self.client = Client.new(host or Config:get('Host'), port or Config:get('Port'))

	self.writeProcessor = WriteProcessor.new(self.tree)
	self.readProcessor = ReadProcessor.new(self.tree)

	self.watcher = Watcher.new(self.tree)
	self.executor = Executor.new()

	self.__prompt = function(_message: string, _changes: Types.Changes?): boolean
		return true
	end
	self.__ready = function(_project: Types.ProjectDetails) end
	self.__sync = function(_kind: Types.MessageKind, _data: any) end

	if Config:get('OpenInEditor') then
		self:__handleOpenInEditor()
	end

	-- watch for `OpenInEditor setting
	table.insert(
		self.connections,
		Config:onChanged('OpenInEditor', function(enabled)
			if enabled then
				self:__handleOpenInEditor()
			else
				self:__cleanConnection('openInEditor')
			end
		end)
	)

	-- watch for `TwoWaySync` setting
	table.insert(
		self.connections,
		Config:onChanged('TwoWaySync', function(enabled)
			if enabled then
				self.watcher:start(self.rootDirs)
			else
				self.watcher:stop()
			end
		end)
	)

	return self
end

function Core:run(): Promise.TypedPromise<nil>
	return Promise.new(function(_, reject)
		self.status = Core.Status.Connecting

		Log.trace('Fetching server details..')

		local project = self.client:fetchDetails():expect()
		self.project = project

		if project.gameId and project.gameId ~= game.GameId then
			local err = Error.new(Error.GameId, game.GameId, project.gameId)

			if not self.__prompt(err.message) or self.status ~= Core.Status.Connecting then
				return reject(err)
			end
		end

		if #project.placeIds > 0 and not table.find(project.placeIds, game.PlaceId) then
			local err = Error.new(Error.PlaceIds, game.PlaceId, project.placeIds)

			if not self.__prompt(err.message) or self.status ~= Core.Status.Connecting then
				return reject(err)
			end
		end

		Log.trace('Subscribing to the server queue..')

		self.client:subscribe():expect()

		Log.trace('Getting initial snapshot..')

		local snapshot = self.client:getSnapshot():expect()

		Log.trace('Initializing processor..')

		local initialChanges = Initializer.new(self.tree):start(snapshot)

		for i, id in ipairs(project.rootDirs) do
			self.rootDirs[i] = self.tree:getInstance(id)
		end

		if self.status ~= Core.Status.Connecting then
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

		self.writeProcessor:applyChanges(initialChanges, true)

		if Config:get('TwoWaySync') then
			self.watcher:start(self.rootDirs)
		end

		self.status = Core.Status.Connected
		self.__ready(project)

		self:__startSyncbackLoop():catch(function(err)
			return reject(err)
		end)

		return self:__startSyncLoop():expect()
	end)
end

function Core:stop()
	self.status = Core.Status.Disconnecting

	self.watcher:stop()

	if self.client.isSubscribed then
		task.spawn(function()
			self.client:unsubscribe():catch(function(err)
				Log.debug('Failed to unsubscribe from the server', err)
			end)
		end)
	end

	Util.clean(self.connections)
end

function Core:onPrompt(callback: (message: string, changes: Types.Changes?) -> boolean)
	self.__prompt = function(message, changes)
		if self.status == Core.Status.Disconnecting then
			return false
		end

		return callback(message, changes)
	end
end

function Core:onReady(callback: (project: Types.ProjectDetails) -> ())
	self.__ready = function(project)
		if self.status == Core.Status.Disconnecting then
			return
		end

		return callback(project)
	end
end

function Core:onSync(callback: (kind: Types.MessageKind, data: any) -> ())
	self.__sync = function(kind, data)
		if self.status == Core.Status.Disconnecting then
			return
		end

		return callback(kind, data)
	end
end

function Core.wasExitGraceful(err: Error.Error)
	return err == Error.GameId or err == Error.PlaceIds or err == Error.TooManyChanges or err == Error.Terminated
end

-- Internal functions

function Core:__startSyncLoop()
	return Promise.new(function(resolve)
		while self.status == Core.Status.Connected do
			local message = self.client:read():expect() :: Types.Message?

			if not message then
				continue
			end

			local kind = next(message) :: Types.MessageKind
			local data = message[kind] :: any

			Log.trace('Received message:', kind)

			if kind == 'SyncChanges' then
				self.writeProcessor:applyChanges(data)
				self.__sync(kind, data)
			elseif kind == 'SyncDetails' then
				self.__sync(kind, data)
			elseif kind == 'ExecuteCode' then
				self.executor:execute(data.code)
			else
				local err = Error.new(Error.UnknownEvent, kind, data)
				Log.warn(err)
			end
		end

		resolve()
	end)
end

function Core:__startSyncbackLoop()
	return Promise.new(function(resolve)
		while self.status == Core.Status.Connected do
			local event = self.watcher:awaitEvent() :: Types.WatcherEvent
			local kind = event.kind

			local snapshot

			print(kind)

			if kind == 'Add' then
				snapshot = self.readProcessor:onAdd(event.instance)
			elseif kind == 'Remove' then
				snapshot = self.readProcessor:onRemove(event.instance)
			else
				snapshot = self.readProcessor:onChange(event.instance, event.property)
			end

			if snapshot then
				print(snapshot)
			end
		end

		resolve()
	end)
end

function Core:__handleOpenInEditor()
	self.connections['openInEditor'] = ScriptEditorService.TextDocumentDidOpen:Connect(function(document)
		if self.status ~= Core.Status.Connected then
			return
		end

		if document:IsCommandBar() then
			Log.trace('Document is a command bar, ignoring')
			return
		end

		local id = self.tree:getId(document:GetScript())

		if not id then
			Log.trace('Document is not synced by Argon, ignoring')
			return
		end

		task.wait()

		local line = document:GetSelectionStart()

		self.client
			:open(id, line)
			:andThen(function()
				document:CloseAsync()
			end)
			:catch(function(err)
				Log.debug('Failed to open document in editor:', err)
			end)
	end)
end

function Core:__cleanConnection(id: string)
	local connection = self.connections[id]

	if connection then
		connection:Disconnect()
		self.connections[id] = nil
	end
end

return Core
