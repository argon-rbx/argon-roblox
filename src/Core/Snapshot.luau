local Argon = script:FindFirstAncestor("Argon")

local Types = require(Argon.Types)

local Meta = require(script.Parent.Meta)

-- Temporary solution for empty Luau maps being serialized as arrays
local function validateProperties(properties: Types.Properties): Types.Properties
	if not next(properties) then
		properties.ArgonEmpty = {
			Bool = true,
		}
	end

	return properties
end

local Snapshot = {}
Snapshot.__index = Snapshot

function Snapshot.new(id: Types.Ref)
	local self = setmetatable({}, Snapshot)

	self.id = id
	self.meta = Meta.new()
	self.parent = nil
	self.name = ""
	self.class = ""
	self.properties = validateProperties({})
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

function Snapshot:withMeta(meta: Types.Meta)
	self.meta = meta
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
	self.properties = validateProperties(properties)
	return self
end

function Snapshot:withChildren(children: { Types.Snapshot })
	self.children = children
	return self
end

return Snapshot
