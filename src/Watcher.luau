local CollectionService = game:GetService("CollectionService")

local Argon = script:FindFirstAncestor("Argon")

local Signal = require(Argon.Packages.Signal)

local Types = require(Argon.Types)
local Log = require(Argon.Log)

local Watcher = {}
Watcher.__index = Watcher

function Watcher.new()
	local self = {
		isActive = false,
		rootInstances = {},
		connections = {},
		tagConnections = {},
		valueInstances = {},
		signal = Signal.new(),
	}

	return setmetatable(self, Watcher)
end

function Watcher:start(rootInstances: { Instance })
	Log.trace("Starting watcher..")

	self.isActive = true
	self.rootInstances = rootInstances

	for _, instance in ipairs(rootInstances) do
		self:__connectEvents(instance)

		for _, descendant in ipairs(instance:GetDescendants()) do
			self:__connectEvents(descendant)
		end
	end

	local tagConnections = {}

	table.insert(
		tagConnections,
		CollectionService.TagAdded:Connect(function(tag)
			self:__watchTag(tag)

			for _, instance in ipairs(CollectionService:GetTagged(tag)) do
				self:__onChanged(instance, "Tags")
			end
		end)
	)

	table.insert(
		tagConnections,
		CollectionService.TagRemoved:Connect(function(tag)
			self:__unwatchTag(tag)
		end)
	)

	self.tagConnections[CollectionService] = tagConnections
end

function Watcher:stop()
	Log.trace("Stopping watcher..")

	self.signal:UnbindAll()

	for _, connections in pairs(self.connections) do
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	for _, tagConnections in pairs(self.tagConnections) do
		for _, tagConnection in ipairs(tagConnections) do
			tagConnection:Disconnect()
		end
	end

	self.isActive = false
	self.rootInstances = {}
	self.connections = {}
	self.tagConnections = {}
	self.valueInstances = {}
end

function Watcher:restart(instances: { Instance })
	if not self.isActive then
		return
	end

	Log.trace("Restarting watcher..")

	self:stop()
	self:start(instances)
end

function Watcher:listen(): Types.WatcherEvent
	return self.signal:Wait()
end

function Watcher:__connectEvents(instance: Instance)
	if instance == workspace.CurrentCamera then
		return
	end

	local connections = {}

	table.insert(
		connections,
		instance.ChildAdded:Connect(function(child)
			self:__onAdded(child)
		end)
	)

	table.insert(
		connections,
		instance.ChildRemoved:Connect(function(child)
			self:__onRemoved(child)
		end)
	)

	if not instance:IsA("ValueBase") then
		table.insert(
			connections,
			instance.Changed:Connect(function(property)
				if property ~= "Parent" then
					self:__onChanged(instance, property)
				end
			end)
		)
	else
		self.valueInstances[instance] = true

		table.insert(
			connections,
			instance.Changed:Connect(function(_value)
				self:__onChanged(instance, "Value")
			end)
		)

		table.insert(
			connections,
			instance.AttributeChanged:Connect(function(_attribute)
				self:__onChanged(instance, "Attributes")
			end)
		)

		for _, tag in ipairs(instance:GetTags()) do
			self:__watchTag(tag)
		end
	end

	self.connections[instance] = connections
end

function Watcher:__watchTag(tag: string)
	if self.tagConnections[tag] then
		return
	end

	local tagConnections = {}

	table.insert(
		tagConnections,
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			if self.valueInstances[instance] then
				self:__onChanged(instance, "Tags")
			end
		end)
	)

	table.insert(
		tagConnections,
		CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
			if self.valueInstances[instance] then
				self:__onChanged(instance, "Tags")
			end
		end)
	)

	self.tagConnections[tag] = tagConnections
end

function Watcher:__unwatchTag(tag: string)
	local tagConnections = self.tagConnections[tag]

	if tagConnections then
		for _, tagConnection in ipairs(tagConnections) do
			tagConnection:Disconnect()
		end

		self.tagConnections[tag] = nil
	end
end

function Watcher:__onAdded(instance: Instance)
	self:__connectEvents(instance)

	self.signal:Fire({
		kind = "Add",
		instance = instance,
	})
end

function Watcher:__onChanged(instance: Instance, property: string)
	self.signal:Fire({
		kind = "Change",
		instance = instance,
		property = property,
	})
end

function Watcher:__onRemoved(instance: Instance)
	local connections = self.connections[instance]

	if connections then
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end

		self.connections[instance] = nil
	end

	if self.valueInstances[instance] then
		self.valueInstances[instance] = nil
	end

	self.signal:Fire({
		kind = "Remove",
		instance = instance,
	})
end

return Watcher
