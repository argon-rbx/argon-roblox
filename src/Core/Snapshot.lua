local Argon = script:FindFirstAncestor('Argon')

local Types = require(Argon.Types)

local Meta = require(script.Parent.Meta)

local Snapshot = {}
Snapshot.__index = Snapshot

function Snapshot.new(id: Types.Ref)
	local self = setmetatable({}, Snapshot)

	self.id = id
	self.meta = Meta.new()
	self.name = ''
	self.class = ''
	self.properties = {}
	self.children = {}

	return self
end

function Snapshot.newAdded(id: Types.Ref)
	local self = setmetatable({}, Snapshot)

	self.id = id
	self.meta = Meta.new()
	self.parent = ''
	self.name = ''
	self.class = ''
	self.properties = {}
	self.children = {}

	return self
end

function Snapshot.newUpdated(id: Types.Ref)
	local self = setmetatable({}, Snapshot)

	self.id = id
	self.meta = nil
	self.name = nil
	self.class = nil
	self.properties = nil

	return self
end

function Snapshot:withParent(parent: Types.Ref)
	self.parent = parent
	return self
end

function Snapshot:withName(name: string)
	self.name = name
	return self
end

function Snapshot:withClass(class: string)
	self.class = class
	return self
end

function Snapshot:withProperties(properties: Types.Properties)
	self.properties = properties
	return self
end

function Snapshot:withChildren(children: { Types.Snapshot })
	self.children = children
	return self
end

return Snapshot
