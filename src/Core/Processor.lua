local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)
local Dom = require(Argon.Dom)
local equals = require(Argon.Helpers.equals)

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

	-- Check if snapshot is new
	if not instance then
		changes:add(snapshot)
		return changes
	end

	-- Diff properties, find updated ones
	do
		local defaultProperties = Dom.getDefaultProperties(instance.ClassName)
		local updatedProperties = {}

		for property, default in pairs(defaultProperties) do
			local value = snapshot.properties[property]

			if value then
				local readSuccess, instanceValue = Dom.readProperty(instance, property)

				if not readSuccess then
					warn(`Failed to read property {property} on {instance:GetFullName()}`)
					continue
				end

				local decodeSuccess, snapshotValue = Dom.EncodedValue.decode(value)

				if not decodeSuccess then
					warn(
						`Failed to decode snapshot property {property} from properties {Util.stringify(
							snapshot.properties
						)}`
					)
					continue
				end

				if not equals(instanceValue, snapshotValue) then
					updatedProperties[property] = value
				end

				-- If snapshot does not have the property we want it to be default
			else
				local readSuccess, instanceValue = Dom.readProperty(instance, property)

				if not readSuccess then
					warn(`Failed to read property {property} on {instance:GetFullName()}`)
					continue
				end

				local _, defaultValue = Dom.EncodedValue.decode(default)

				if not equals(instanceValue, defaultValue) then
					updatedProperties[property] = default
				end
			end
		end

		if Util.len(updatedProperties) > 0 then
			changes:update({
				id = snapshot.id,
				properties = updatedProperties,
			})
		end
	end

	-- Diff snapshot children, find new ones
	for _, child in snapshot.children do
		local childInstance = self.tree:getInstance(child.id)

		if not childInstance then
			changes:add(child)
		end
	end

	-- Diff instance children, find removed ones
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
