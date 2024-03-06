local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)
local Dom = require(Argon.Dom)

local Types = require(script.Parent.Types)
local Changes = require(script.Parent.Changes)

local Processor = {}
Processor.__index = Processor

function Processor.new(tree)
	local self = {
		tree = tree,
	}

	return setmetatable(self, Processor)
end

function Processor:initialize(snapshot: Types.Snapshot): Types.Changes
	local function hydrate(snapshot: Types.Snapshot, instance: Instance)
		self.tree:insert(instance, snapshot.id)

		local children = instance:GetChildren()
		local hydrated = table.create(#children, false)

		for _, snapshotChild in ipairs(snapshot.children) do
			for index, child in children do
				if hydrated[index] then
					continue
				end

				if child.Name == snapshotChild.name and child.ClassName == snapshotChild.class then
					hydrate(snapshotChild, child)
					hydrated[index] = true
					break
				end
			end
		end
	end

	hydrate(snapshot, game)

	local changes = Changes.new()

	for _, child in ipairs(snapshot.children) do
		changes:join(self:diff(child))
	end

	return changes
end

function Processor:diff(snapshot: Types.Snapshot): Types.Changes
	local changes = Changes.new()

	local instance = self.tree:getInstance(snapshot.id)

	if not instance then
		changes:add(snapshot)
		return changes
	end

	local defaultProperties = Dom.getDefaultProperties(instance.ClassName)

	for property, default in pairs(defaultProperties) do
		if snapshot.properties[property] == nil then
			local updatedProperties = {}

			if snapshot.properties[property] then
				print('TODO')
			else
				local readSuccess, instanceValue = Dom.readProperty(instance, property)

				if not readSuccess then
					warn(`Failed to read property {property} on {instance:GetFullName()}`)
					continue
				end

				local _, defaultValue = Dom.EncodedValue.decode(default)

				print(property)
				print(instanceValue, defaultValue)
				print(instanceValue == defaultValue)
			end

			if Util.len(updatedProperties) > 0 then
				changes:update({
					id = snapshot.id,
					properties = updatedProperties,
				})
			end
		end
	end

	for _, child in snapshot.children do
		local childInstance = self.tree:getInstance(child.id)

		if not childInstance then
			changes:add(child)
		end
	end

	for _, child in instance:GetChildren() do
		local childId = self.tree:getId(child)

		if childId then
			local childSnapshot = Util.filter(snapshot.children, function(child)
				return child.id == childId
			end)

			changes:join(self:diff(childSnapshot))
		else
			changes:remove(child)
		end
	end

	return changes
end

return Processor
