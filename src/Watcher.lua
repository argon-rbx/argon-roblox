local Argon = script:FindFirstAncestor('Argon')

local Signal = require(Argon.Packages.Signal)

local Types = require(Argon.Types)

local Watcher = {}
Watcher.__index = Watcher

function Watcher.new(tree)
	local self = {
		tree = tree,
		rootDirs = {},
		connections = {},
		signal = Signal.new(),
	}

	return setmetatable(self, Watcher)
end

function Watcher:start(rootDirs: { Instance })
	for _, instance in ipairs(rootDirs) do
		self:__connectEvents(instance)

		for _, descendant in ipairs(instance:GetDescendants()) do
			self:__connectEvents(descendant)
		end
	end
end

function Watcher:stop()
	self.signal:UnbindAll()

	for _, connections in pairs(self.connections) do
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
	end

	self.connections = {}
end

function Watcher:awaitEvent(): Types.WatcherEvent
	return self.signal:Wait()
end

function Watcher:__connectEvents(instance: Instance)
	local connections = {}

	table.insert(
		connections,
		instance.ChildAdded:Connect(function(child)
			self:__onAdded(child)
		end)
	)

	table.insert(
		connections,
		instance.Changed:Connect(function(property)
			self:__onChanged(instance, property)
		end)
	)

	table.insert(
		connections,
		instance.ChildRemoved:Connect(function(child)
			self:__onRemoved(child)
		end)
	)

	self.connections[instance] = connections
end

function Watcher:__onAdded(instance: Instance)
	self:__connectEvents(instance)

	self.signal:Fire({
		kind = 'Add',
		instance = instance,
	})
end

function Watcher:__onChanged(instance: Instance, property: string)
	if property == 'Parent' then
		return
	end

	self.signal:Fire({
		kind = 'Change',
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

	self.signal:Fire({
		kind = 'Remove',
		instance = instance,
	})
end

return Watcher
