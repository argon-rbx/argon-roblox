local Argon = script:FindFirstAncestor("Argon")

local Types = require(Argon.Types)
local Dom = require(Argon.Dom)
local Log = require(Argon.Log)
local Config = require(Argon.Config)

local equals = require(Argon.Helpers.equals)
local generateRef = require(Argon.Helpers.generateRef)

local Snapshot = require(script.Parent.Parent.Snapshot)
local Error = require(script.Parent.Parent.Error)

local function syncProperties(instance: Instance, property: string?): boolean
	return instance:IsA("LuaSourceContainer") or Config:get("SyncbackProperties") or property == "Name"
end

local function containsScripts(instance: Instance): boolean
	for _, descendant in ipairs(instance:GetDescendants()) do
		if descendant:IsA("LuaSourceContainer") then
			return true
		end
	end

	return false
end

-- Temporary solution for serde failing to deserialize empty HashMap
local function validateProperties(properties: Types.Properties)
	if not next(properties) then
		properties.ArgonEmpty = {
			Bool = true,
		}
	end
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

	local parentId = __parentId or self.tree:getId(instance.Parent)

	if not parentId then
		Log.trace("Unknown instance. Skipping..")
		return nil
	end

	local id = generateRef()
	local properties = {}
	local children = {}

	if syncProperties(instance) then
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
		table.insert(children, self:onAdd(child, id))
	end

	local snapshot

	if __parentId then
		snapshot = Snapshot.new(id)
	else
		snapshot = Snapshot.newAdded(id):withParent(parentId)
	end

	self.tree:insertInstance(instance, id, snapshot.meta)

	validateProperties(properties)

	return snapshot
		:withName(instance.Name)
		:withClass(instance.ClassName)
		:withProperties(properties)
		:withChildren(children)
end

function ReadProcessor:onChange(instance: Instance, property: string?): Types.UpdatedSnapshot?
	Log.trace("Detected change of", instance, property)

	local id = self.tree:getId(instance)

	if not id then
		Log.trace("Unknown instance. Skipping..")
		return nil
	end

	if not syncProperties(instance, property) and property then
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

	validateProperties(properties)

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

function ReadProcessor:onAddOnlyCode(instance: Instance, __parentId: Types.Ref?): Types.AddedSnapshot?
	Log.trace("Detected addition of", instance, "(only code)")

	local parentId = __parentId or self.tree:getId(instance.Parent)

	if not parentId then
		Log.trace("Unknown instance. Skipping..")
		return nil
	end

	local isScript = instance:IsA("LuaSourceContainer")

	if not isScript and not containsScripts(instance) then
		Log.trace("Instance does not contain any scripts. Skipping..")
		return nil
	end

	local id = generateRef()
	local properties = {}
	local children = {}

	if isScript then
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
		local snapshot = self:onAddOnlyCode(child, id)

		if snapshot then
			table.insert(children, snapshot)
		end
	end

	local snapshot

	if __parentId then
		snapshot = Snapshot.new(id)
	else
		snapshot = Snapshot.newAdded(id):withParent(parentId)
	end

	self.tree:insertInstance(instance, id, snapshot.meta)

	validateProperties(properties)

	return snapshot
		:withName(instance.Name)
		:withClass(instance.ClassName)
		:withProperties(properties)
		:withChildren(children)
end

return ReadProcessor
