local Argon = script:FindFirstAncestor('Argon')

local Dom = require(Argon.Dom)
local Log = require(Argon.Log)
local Util = require(Argon.Util)
local Types = require(Argon.Types)
local Config = require(Argon.Config)
local equals = require(Argon.Helpers.equals)

local Error = require(script.Parent.Error)
local Changes = require(script.Parent.Changes)

local ReadProcessor = require(script.Read)
local WriteProcessor = require(script.Write)

local Processor = {}
Processor.__index = Processor

function Processor.new(tree)
	local self = {
		tree = tree,
		read = ReadProcessor.new(tree),
		write = WriteProcessor.new(tree),
	}

	return setmetatable(self, Processor)
end

function Processor:init(snapshot: Types.Snapshot, initialSyncServer: boolean, skipDiff: boolean): Types.Changes
	Log.trace('Hydrating initial snapshot..')

	self:hydrate(snapshot, game)

	if skipDiff then
		return Changes.new()
	end

	Log.trace('Diffing initial snapshot..')

	local changes = Changes.new()

	for _, child in ipairs(snapshot.children) do
		changes:join(self:diff(child, snapshot.id, not initialSyncServer))
	end

	if not Config:get('OverridePackages') and initialSyncServer then
		local temp = {}

		for _, snapshot in ipairs(changes.additions) do
			local instance = self.tree:getInstance(snapshot.parent)

			if instance and Util.isPackageDescendant(instance) then
				table.insert(temp, snapshot)
			end
		end

		for i, snapshot in ipairs(temp) do
			table.remove(changes.additions, table.find(changes.additions, snapshot))
			temp[i] = nil
		end

		for _, snapshot in ipairs(changes.updates) do
			local instance = self.tree:getInstance(snapshot.id)

			if instance and Util.isPackageDescendant(instance) then
				table.insert(temp, snapshot)
			end
		end

		for i, snapshot in ipairs(temp) do
			table.remove(changes.updates, table.find(changes.updates, snapshot))
			temp[i] = nil
		end

		for _, instance in ipairs(changes.removals) do
			if Util.isPackageDescendant(instance) then
				table.insert(temp, instance)
			end
		end

		for i, instance in ipairs(temp) do
			table.remove(changes.removals, table.find(changes.removals, instance))
			temp[i] = nil
		end
	end

	return changes
end

function Processor:hydrate(snapshot: Types.Snapshot, instance: Instance)
	self.tree:insertInstance(instance, snapshot.id, snapshot.meta)

	local children = instance:GetChildren()
	local hydrated = table.create(#children, false)

	for _, snapshotChild in ipairs(snapshot.children) do
		for index, child in children do
			if hydrated[index] then
				continue
			end

			if child.Name == snapshotChild.name and child.ClassName == snapshotChild.class then
				self:hydrate(snapshotChild, child)
				hydrated[index] = true
				break
			end
		end
	end
end

function Processor:diff(snapshot: Types.Snapshot, parent: Types.Ref, ignoreMeta: boolean): Types.Changes
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
					local err = Error.new(Error.ReadFailed, property, instance, instanceValue.kind)
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
					local err = Error.new(Error.ReadFailed, property, instance, instanceValue.kind)
					Log.warn(err)

					continue
				end

				local _, defaultValue = Dom.EncodedValue.decode(default)

				if not equals(instanceValue, defaultValue) then
					updatedProperties[property] = default
				end
			end
		end

		if next(updatedProperties) then
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

			changes:join(self:diff(childSnapshot, snapshot.id, ignoreMeta))
		elseif (not snapshot.meta.keepUnknowns or ignoreMeta) and Dom.isCreatable(child.ClassName) then
			changes:remove(child)
		end
	end

	return changes
end

function Processor:reverseChanges(changes: Types.Changes): Types.Changes
	Log.trace('Reversing changes..')

	local reversed = Changes.new()

	for _, snapshot in ipairs(changes.additions) do
		reversed:remove(buffer.fromstring(snapshot.id))
	end

	for _, snapshot in ipairs(changes.updates) do
		local instance = self.tree:getInstance(snapshot.id)
		reversed:update(self.read:onChange(instance))
	end

	if not Config:get('OnlyCodeMode') then
		for _, instance in ipairs(changes.removals) do
			reversed:add(self.read:onAdd(instance))
		end
	else
		for _, instance in ipairs(changes.removals) do
			local snapshot = self.read:onAddOnlyCode(instance)

			if snapshot then
				reversed:add(snapshot)
			end
		end
	end

	return reversed
end

return Processor
