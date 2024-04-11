local Argon = script:FindFirstAncestor('Argon')

local Types = require(Argon.Types)
local Dom = require(Argon.Dom)
local Log = require(Argon.Log)
local equals = require(Argon.Helpers.equals)
local generateRef = require(Argon.Helpers.generateRef)

local Snapshot = require(script.Parent.Parent.Snapshot)
local Error = require(script.Parent.Parent.Error)

local ReadProcessor = {}
ReadProcessor.__index = ReadProcessor

function ReadProcessor.new(tree)
	return setmetatable({
		tree = tree,
	}, ReadProcessor)
end

function ReadProcessor:onAdd(instance: Instance, __parentId: Types.Ref?): Types.AddedSnapshot?
	local parentId = __parentId or self.tree:getId(instance.Parent)

	if not parentId then
		return
	end

	Log.trace('Detected addition of', instance)

	local id = generateRef()
	local properties = {}
	local children = {}

	for property, default in Dom.getDefaultProperties(instance.ClassName) do
		local readSuccess, instanceValue = Dom.readProperty(instance, property)

		if not readSuccess then
			local err = Error.new(Error.ReadFailed, property, instance)
			Log.warn(err)

			continue
		end

		local _, defaultValue = Dom.EncodedValue.decode(default)

		if not equals(instanceValue, defaultValue) then
			properties[property] = instanceValue
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

	self.tree:insertInstance(instance, buffer.tostring(id), snapshot.meta)

	return snapshot
		:withName(instance.Name)
		:withClass(instance.ClassName)
		:withProperties(properties)
		:withChildren(children)
end

function ReadProcessor:onRemove(instance: Instance): Types.Ref?
	local id = self.tree:getId(instance)

	if not id then
		return
	end

	Log.trace('Detected removal of', instance)

	self.tree:removeById(id)

	return buffer.fromstring(id)
end

function ReadProcessor:onChange(instance: Instance, property: string)
	local id = self.tree:getId(instance)

	if not id then
		return
	end

	Log.trace('Detected change of', instance, property)

	if property == 'Name' then
		return Snapshot.newUpdated(buffer.fromstring(id)):withName(instance.Name)
	end

	local properties = {}

	for property, default in Dom.getDefaultProperties(instance.ClassName) do
		local readSuccess, instanceValue = Dom.readProperty(instance, property)

		if not readSuccess then
			local err = Error.new(Error.ReadFailed, property, instance)
			Log.warn(err)

			continue
		end

		local _, defaultValue = Dom.EncodedValue.decode(default)

		if not equals(instanceValue, defaultValue) then
			properties[property] = instanceValue
		end
	end

	return Snapshot.newUpdated(buffer.fromstring(id)):withProperties(properties)
end

return ReadProcessor
