local Argon = script:FindFirstAncestor('Argon')

local Dom = require(Argon.Dom)
local Log = require(Argon.Log)
local Util = require(Argon.Util)
local Types = require(Argon.Types)
local equals = require(Argon.Helpers.equals)

local Error = require(script.Parent.Error)
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
		self.tree:insertInstance(instance, snapshot.id)

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

	local function diff(snapshot: Types.Snapshot, parent: Types.Ref): Types.Changes
		local changes = Changes.new()

		local instance = self.tree:getInstance(snapshot.id)

		-- Check if snapshot is new
		if not instance then
			changes:add(snapshot, parent)
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
						local err = Error.new(Error.ReadFailed, property, instance)
						Log.warn(err)

						continue
					end

					local decodeSuccess, snapshotValue = Dom.EncodedValue.decode(value)

					if not decodeSuccess then
						local err = Error.new(Error.DecodeFailed, property, value)
						Log.warn(err)

						continue
					end

					if not equals(instanceValue, snapshotValue) then
						updatedProperties[property] = value
					end

				-- If snapshot does not have the property we want it to be default
				else
					local readSuccess, instanceValue = Dom.readProperty(instance, property)

					if not readSuccess then
						local err = Error.new(Error.ReadFailed, property, instance)
						Log.warn(err)

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
				changes:add(child, snapshot.id)
			end
		end

		-- Diff instance children, find removed ones
		for _, child in instance:GetChildren() do
			local childId = self.tree:getId(child)

			if childId then
				local childSnapshot = Util.filter(snapshot.children, function(child)
					return child.id == childId
				end)

				changes:join(diff(childSnapshot, snapshot.id))
			elseif not snapshot.meta.keepUnknowns and Dom.isCreatable(child.ClassName) then
				print(snapshot.meta)
				changes:remove(child)
			end
		end

		return changes
	end

	Log.trace('Hydrating initial snapshot..')

	hydrate(snapshot, game)

	Log.trace('Diffing initial snapshot..')

	local changes = Changes.new()

	for _, child in ipairs(snapshot.children) do
		changes:join(diff(child, snapshot.id))
	end

	return changes
end

function Processor:applyChanges(changes: Types.Changes)
	Log.trace('Applying changes..')

	for _, addition in ipairs(changes.additions) do
		self:applyAddition(addition)
	end

	for _, update in ipairs(changes.updates) do
		self:applyUpdate(update)
	end

	for _, removal in ipairs(changes.removals) do
		self:applyRemoval(removal)
	end
end

function Processor:applyAddition(snapshot: Types.AddedSnapshot)
	Log.trace('Applying addition of', snapshot)

	local parent = self.tree:getInstance(snapshot.parent)

	local instance = Instance.new(snapshot.class)
	instance.Name = snapshot.name

	for property, value in pairs(snapshot.properties) do
		local decodeSuccess, decodedValue = Dom.EncodedValue.decode(value)

		if not decodeSuccess then
			local err = Error.new(Error.DecodeFailed, property, value)
			Log.warn(err)

			continue
		end

		local writeSuccess = Dom.writeProperty(instance, property, decodedValue)

		if not writeSuccess then
			local err = Error.new(Error.WriteFailed, property, instance, decodedValue)
			Log.warn(err)
		end
	end

	instance.Parent = parent
	self.tree:insertInstance(instance, snapshot.id, snapshot.meta)

	for _, child in ipairs(snapshot.children) do
		child.parent = snapshot.id

		self:applyAddition(child)
	end
end

function Processor:applyUpdate(snapshot: Types.UpdatedSnapshot)
	Log.trace('Applying update of', snapshot)

	local instance = self.tree:getInstance(snapshot.id)
	local defaultProperties = Dom.getDefaultProperties(snapshot.class or instance.ClassName)

	if snapshot.meta then
		self.tree:updateMeta(snapshot.id, snapshot.meta)

		if not snapshot.meta.keepUnknowns then
			for _, child in ipairs(instance:GetChildren()) do
				self:applyRemoval(child)
			end
		end
	end

	if snapshot.class then
		local newInstance = Instance.new(snapshot.class)
		newInstance.Name = instance.Name

		for property in pairs(defaultProperties) do
			local readSuccess, instanceValue = Dom.readProperty(instance, property)

			if readSuccess then
				local writeSuccess = Dom.writeProperty(newInstance, property, instanceValue)

				if not writeSuccess then
					local err = Error.new(Error.WriteFailed, property, newInstance, instanceValue)
					Log.warn(err)
				end
			end
		end

		for _, child in ipairs(instance:GetChildren()) do
			child.Parent = newInstance
		end

		newInstance.Parent = instance.Parent

		instance:Destroy()
		self.tree:updateInstance(snapshot.id, newInstance)

		instance = newInstance
	end

	if snapshot.name then
		instance.Name = snapshot.name
	end

	if snapshot.properties then
		for property, default in pairs(defaultProperties) do
			local value = snapshot.properties[property]

			if value then
				local decodeSuccess, snapshotValue = Dom.EncodedValue.decode(value)

				if not decodeSuccess then
					local err = Error.new(Error.DecodeFailed, property, value)
					Log.warn(err)

					continue
				end

				local writeSuccess = Dom.writeProperty(instance, property, snapshotValue)

				if not writeSuccess then
					local err = Error.new(Error.WriteFailed, property, instance, snapshotValue)
					Log.warn(err)
				end
			else
				local _, defaultValue = Dom.EncodedValue.decode(default)
				local writeSuccess = Dom.writeProperty(instance, property, defaultValue)

				if not writeSuccess then
					local err = Error.new(Error.WriteFailed, property, instance, defaultValue)
					Log.warn(err)
				end
			end
		end
	end
end

function Processor:applyRemoval(object: Types.Ref | Instance)
	Log.trace('Applying removal of', object)

	if typeof(object) == 'Instance' then
		self.tree:removeByInstance(object)
		object:Destroy()
	else
		local instance = self.tree:getInstance(object)

		self.tree:removeById(object)
		instance:Destroy()
	end
end

return Processor
