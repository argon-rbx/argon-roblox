local ChangeHistoryService = game:GetService('ChangeHistoryService')

local Argon = script:FindFirstAncestor('Argon')

local Dom = require(Argon.Dom)
local Log = require(Argon.Log)
local Types = require(Argon.Types)
local Config = require(Argon.Config)
local generateRef = require(Argon.Helpers.generateRef)

local Error = require(script.Parent.Parent.Error)

local function setWaypoint(action: string?)
	ChangeHistoryService:SetWaypoint(`Argon {action or 'sync'}: {DateTime.now():FormatLocalTime('LTS', 'en-us')}`)
end

local WriteProcessor = {}
WriteProcessor.__index = WriteProcessor

function WriteProcessor.new(tree)
	return setmetatable({
		tree = tree,
		lastRemovedInstance = nil,
	}, WriteProcessor)
end

function WriteProcessor:applyChanges(changes: Types.Changes, initial: boolean?)
	Log.trace('Applying changes..')

	setWaypoint()

	for _, snapshot in ipairs(changes.additions) do
		self:applyAddition(snapshot)
	end

	for _, snapshot in ipairs(changes.updates) do
		self:applyUpdate(snapshot, initial)
	end

	for _, object in ipairs(changes.removals) do
		self:applyRemoval(object)
	end
end

function WriteProcessor:applyAddition(snapshot: Types.AddedSnapshot)
	Log.trace('Applying addition of', snapshot)

	local parent = self.tree:getInstance(snapshot.parent)

	if not parent then
		local err = Error.new(Error.NoInstanceAdd, snapshot)
		Log.warn(err)

		return
	end

	local instance

	if Dom.isCreatable(snapshot.class) then
		instance = Instance.new(snapshot.class)
	elseif parent == game then
		local service = game:FindFirstChildOfClass(snapshot.class)

		if service then
			instance = service
		else
			local err = Error.new(Error.HydrationFailed, snapshot)
			Log.warn(err)

			return
		end
	else
		local err = Error.new(Error.NotCreatable, snapshot.class)
		Log.warn(err)

		return
	end

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

	setWaypoint('add')
end

function WriteProcessor:applyUpdate(snapshot: Types.UpdatedSnapshot, initial: boolean?)
	Log.trace('Applying update of', snapshot)

	local instance = self.tree:getInstance(snapshot.id)

	if not instance then
		local err = Error.new(Error.NoInstanceUpdate, snapshot)
		Log.warn(err)

		return
	end

	local defaultProperties

	if snapshot.meta then
		self.tree:updateMeta(snapshot.id, snapshot.meta)

		if not snapshot.meta.keepUnknowns and not Config:get('KeepUnknowns') then
			for _, child in ipairs(instance:GetChildren()) do
				self:applyRemoval(child)
			end
		end
	end

	if snapshot.class then
		defaultProperties = Dom.getDefaultProperties(snapshot.class)

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
		if initial then
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
		else
			for property, default in pairs(defaultProperties or Dom.getDefaultProperties(instance.ClassName)) do
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

	setWaypoint('update')
end

function WriteProcessor:applyRemoval(object: Types.Ref | Instance)
	Log.trace('Applying removal of', object)

	if typeof(object) == 'Instance' then
		self.tree:removeByInstance(object)
		object:Destroy()
	else
		local instance = self.tree:getInstance(object)

		if not instance then
			local err = Error.new(Error.NoInstanceRemove, object)
			Log.warn(err)

			return
		end

		if not Dom.isCreatable(instance.ClassName) then
			local err = Error.new(Error.NotRemovable, instance.ClassName)
			Log.warn(err)

			return
		end

		self.lastRemovedInstance = {
			instance = instance:Clone(),
			parent = instance.Parent,
		}

		self.tree:removeById(object)
		instance:Destroy()
	end

	setWaypoint('remove')
end

function WriteProcessor:undoLastRemoval()
	if not self.lastRemovedInstance then
		Log.warn('Argon failed to restore the last removed instance')
		return
	end

	local instance = self.lastRemovedInstance.instance
	instance.Parent = self.lastRemovedInstance.parent

	self.lastRemovedInstance = nil

	if not Config:get('TwoWaySync') then
		local function walk(instance)
			self.tree:insertInstance(instance, generateRef(true))

			for _, child in ipairs(instance:GetChildren()) do
				walk(child)
			end
		end

		walk(instance)
	end

	print('Argon successfully restored this instance, you can ignore the warning above')

	setWaypoint('undo')
end

return WriteProcessor
