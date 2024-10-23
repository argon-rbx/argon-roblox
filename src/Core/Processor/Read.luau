local Argon = script:FindFirstAncestor("Argon")

local Types = require(Argon.Types)
local Dom = require(Argon.Dom)
local Log = require(Argon.Log)
local Config = require(Argon.Config)

local equals = require(Argon.Helpers.equals)
local generateRef = require(Argon.Helpers.generateRef)

local Snapshot = require(script.Parent.Parent.Snapshot)
local Error = require(script.Parent.Parent.Error)

local function isScriptRelated(instance: Instance): boolean
	return instance:IsA("LuaSourceContainer") or instance:FindFirstChildWhichIsA("LuaSourceContainer", true) ~= nil
end

local ReadProcessor = {}
ReadProcessor.__index = ReadProcessor

function ReadProcessor.new(tree)
	return setmetatable({
		tree = tree,
	}, ReadProcessor)
end

function ReadProcessor:onAdd(instance: Instance, __parentId: Types.Ref?): Types.AddedSnapshot?
	Log.trace("Detected addition of", instance)

	local isScriptRelated = isScriptRelated(instance)

	if not isScriptRelated then
		Log.trace("Instance is not script related (Only Code Mode). Skipping..")
		return nil
	end

	local parentId = __parentId or self.tree:getId(instance.Parent)

	if not parentId and not (Config:get("OnlyCodeMode") and isScriptRelated) then
		Log.trace("Unknown instance. Skipping..")
		return nil
	end

	local id = generateRef()
	local properties = {}
	local children = {}

	if ReadProcessor.shouldSyncProperties(instance) then
		for property, default in Dom.getDefaultProperties(instance.ClassName) do
			local readSuccess, instanceValue = Dom.readProperty(instance, property)

			if not readSuccess then
				local err = Error.new(Error.ReadFailed, property, instance, instanceValue.kind)
				Log.warn(err)

				continue
			end

			local _, defaultValue = Dom.EncodedValue.decode(default)

			if not equals(instanceValue, defaultValue) then
				local propertyType = next(default)
				local encodeSuccess, encodedValue = Dom.EncodedValue.encode(instanceValue, propertyType)

				if not encodeSuccess then
					local err = Error.new(Error.EncodeFailed, property, instanceValue)
					Log.warn(err)

					continue
				end

				properties[property] = encodedValue
			end
		end
	end

	for _, child in ipairs(instance:GetChildren()) do
		local snapshot = self:onAdd(child, id)

		if snapshot then
			table.insert(children, snapshot)
		end
	end

	local snapshot = Snapshot.new(id)
		:withName(instance.Name)
		:withClass(instance.ClassName)
		:withProperties(properties)
		:withChildren(children)

	self.tree:insertInstance(instance, id, snapshot.meta)

	if __parentId then
		return snapshot
	end

	if parentId then
		snapshot.parent = parentId
	else
		local currentInstance = instance
		local currentSnapshot = nil
		local rootId = nil

		repeat
			parentId = generateRef()
			currentInstance = currentInstance.Parent
			rootId = self.tree:getId(currentInstance)

			if rootId then
				break
			end

			-- In theory this should never happen
			if currentInstance == game then
				Log.warn("Failed to find root instance for", instance)
				return nil
			end

			currentSnapshot = Snapshot.new(parentId)
				:withName(currentInstance.Name)
				:withClass(currentInstance.ClassName)
				:withChildren({ snapshot })

			self.tree:insertInstance(currentInstance, parentId, currentSnapshot.meta)
		until rootId

		currentSnapshot.parent = rootId
		snapshot = currentSnapshot
	end

	return snapshot
end

function ReadProcessor:onChange(instance: Instance, property: string?): Types.UpdatedSnapshot?
	Log.trace("Detected change of", instance, property)

	local id = self.tree:getId(instance)

	if not id then
		Log.trace("Unknown instance. Skipping..")
		return nil
	end

	local isScriptRelated = isScriptRelated(instance)

	if not isScriptRelated then
		Log.trace("Instance is not script related (Only Code Mode). Skipping..")
		return nil
	end

	if property and not ReadProcessor.shouldSyncProperties(instance, property) then
		Log.trace("Instance does not pass sync filter. Skipping..")
		return nil
	end

	if property == "Name" then
		return Snapshot.newUpdated(id):withName(instance.Name)
	end

	local properties = {}

	for property, default in Dom.getDefaultProperties(instance.ClassName) do
		local readSuccess, instanceValue = Dom.readProperty(instance, property)

		if not readSuccess then
			local err = Error.new(Error.ReadFailed, property, instance, instanceValue.kind)
			Log.warn(err)

			continue
		end

		local _, defaultValue = Dom.EncodedValue.decode(default)

		if not equals(instanceValue, defaultValue) then
			local propertyType = next(default)
			local encodeSuccess, encodedValue = Dom.EncodedValue.encode(instanceValue, propertyType)

			if not encodeSuccess then
				local err = Error.new(Error.EncodeFailed, property, instanceValue)
				Log.warn(err)

				continue
			end

			properties[property] = encodedValue
		end
	end

	return Snapshot.newUpdated(id):withProperties(properties)
end

function ReadProcessor:onRemove(instance: Instance): Types.Ref?
	Log.trace("Detected removal of", instance)

	local id = self.tree:getId(instance)

	if not id then
		Log.trace("Unknown instance. Skipping..")
		return nil
	end

	self.tree:removeById(id)

	return id
end

function ReadProcessor.shouldSyncProperties(instance: Instance, property: string?): boolean
	return instance:IsA("LuaSourceContainer") or Config:get("SyncbackProperties") or property == "Name"
end

return ReadProcessor
