local ChangeHistoryService = game:GetService("ChangeHistoryService")

local Argon = script:FindFirstAncestor("Argon")

local Dom = require(Argon.Dom)
local Log = require(Argon.Log)
local Types = require(Argon.Types)
local Config = require(Argon.Config)

local equals = require(Argon.Helpers.equals)

local Error = require(script.Parent.Parent.Error)

local MESH_RELOAD_PROPERTIES = { "MeshContent", "InitialSize" }

local function setWaypoint(action: string, name: string?)
	name = name and ` "{name}"` or ""
	ChangeHistoryService:SetWaypoint(`Argon: {action}{name} [{DateTime.now():FormatLocalTime("LTS", "en-us")}]`)
end

local function loadMesh(path: string)
	local success, mesh = pcall(function()
		return game:GetObjects("rbxasset://argon/" .. path)[1]
	end)

	if not success then
		local err = Error.new(Error.MeshLoadFailed, mesh)
		Log.warn(err)

		return nil
	end

	return mesh
end

local function shouldReloadMesh(mesh: MeshPart, properties: Types.Properties?)
	if not properties then
		return false
	end

	for _, property in MESH_RELOAD_PROPERTIES do
		local value = properties[property]

		if not value then
			continue
		end

		local decodeSuccess, snapshotValue = Dom.EncodedValue.decode(value)

		if not decodeSuccess then
			local err = Error.new(Error.DecodeFailed, property, value)
			Log.warn(err)

			continue
		end

		property = property == "InitialSize" and "MeshSize" or property

		if not equals(mesh[property], snapshotValue) then
			return true
		end
	end

	return false
end

local function warnNotCreatable(class: string)
	local err = Error.new(Error.NotCreatable, class)

	if class == "PackageLink" and not Config:get("OverridePackages") then
		Log.info(err)
	else
		Log.warn(err)
	end
end

local WriteProcessor = {}
WriteProcessor.__index = WriteProcessor

function WriteProcessor.new(tree, client)
	return setmetatable({
		tree = tree,
		client = client,
	}, WriteProcessor)
end

function WriteProcessor:applyChanges(changes: Types.Changes, initial: boolean?)
	Log.trace("Applying changes..")

	setWaypoint("Sync")

	for _, snapshot in changes.additions do
		self:applyAddition(snapshot, initial)
	end

	for _, snapshot in changes.updates do
		self:applyUpdate(snapshot, initial)
	end

	for _, object in changes.removals do
		self:applyRemoval(object, initial)
	end

	if initial then
		setWaypoint("Initial Sync")
	end
end

function WriteProcessor:applyAddition(
	snapshot: Types.AddedSnapshot,
	initial: boolean?,
	skipExisting: boolean?
): Instance?
	Log.trace("Applying addition of", snapshot)

	local parent = self.tree:getInstance(snapshot.parent)

	if not parent then
		if Config:get("LiveHydrate") then
			local addedSnapshot = self.client:getSnapshot(snapshot.parent):expect()

			if addedSnapshot then
				parent = self:applyAddition(addedSnapshot, initial, true)
				skipExisting = true

				Log.info("Live hydrated parent:", parent)
			end
		end

		if not parent then
			local err = Error.new(Error.NoInstanceAdd, snapshot)
			Log.warn(err)

			return
		end
	end

	if skipExisting then
		local instance = parent:FindFirstChild(snapshot.name)

		if instance and instance:IsA(snapshot.class) then
			return instance
		end
	end

	local instance
	local isService = false

	if Dom.isCreatable(snapshot.class) then
		instance = Instance.new(snapshot.class)

		if snapshot.meta.meshSource then
			instance = loadMesh(snapshot.meta.meshSource)

			if not instance then
				return
			end
		end
	elseif parent == game then
		local service = game:FindFirstChildOfClass(snapshot.class)

		if service then
			instance = service
			isService = true
		else
			local err = Error.new(Error.HydrationFailed, snapshot)
			Log.warn(err)

			return
		end
	else
		warnNotCreatable(snapshot.class)
		return
	end

	instance.Name = snapshot.name

	for property, value in snapshot.properties do
		local decodeSuccess, decodedValue = Dom.EncodedValue.decode(value)

		if not decodeSuccess then
			local err = Error.new(Error.DecodeFailed, property, value)
			Log.warn(err)

			continue
		end

		local writeSuccess, reason = Dom.writeProperty(instance, property, decodedValue)

		if not writeSuccess then
			local err = Error.new(Error.WriteFailed, property, instance, reason.kind)
			Log.warn(err)
		end
	end

	if not isService then
		instance.Parent = parent
	end

	self.tree:insertInstance(instance, snapshot.id, snapshot.meta)

	for _, child in snapshot.children do
		child.parent = snapshot.id

		self:applyAddition(child, initial)
	end

	if not initial then
		setWaypoint("Add", instance.Name)
	end

	return instance
end

function WriteProcessor:applyUpdate(snapshot: Types.UpdatedSnapshot, initial: boolean?): Instance?
	Log.trace("Applying update of", snapshot)

	local instance = self.tree:getInstance(snapshot.id)

	if not instance then
		if Config:get("LiveHydrate") then
			local addedSnapshot = self.client:getSnapshot(snapshot.id):expect()

			if addedSnapshot then
				instance = self:applyAddition(addedSnapshot, initial)
				Log.info("Live hydrated instance:", instance)
			end
		end

		if not instance then
			local err = Error.new(Error.NoInstanceUpdate, snapshot)
			Log.warn(err)

			return
		end
	end

	local defaultProperties

	if snapshot.meta then
		self.tree:updateMeta(snapshot.id, snapshot.meta)

		if not snapshot.meta.keepUnknowns and not Config:get("KeepUnknowns") then
			for _, child in instance:GetChildren() do
				if self.tree:getId(child) then
					continue
				end

				self:applyRemoval(child)
			end
		end
	end

	if
		snapshot.class
		or (snapshot.meta and snapshot.meta.meshSource and shouldReloadMesh(instance, snapshot.properties))
	then
		local newInstance

		if snapshot.class then
			if not Dom.isCreatable(snapshot.class) then
				warnNotCreatable(snapshot.class)
				return
			end

			newInstance = Instance.new(snapshot.class)
			defaultProperties = Dom.getDefaultProperties(snapshot.class)
		else
			newInstance = loadMesh(snapshot.meta.meshSource :: string)

			if not newInstance then
				return
			end

			defaultProperties = Dom.getDefaultProperties(newInstance.ClassName)
		end

		newInstance.Name = instance.Name

		for property in defaultProperties do
			local readSuccess, instanceValue = Dom.readProperty(instance, property)

			if readSuccess then
				local writeSuccess, reason = Dom.writeProperty(newInstance, property, instanceValue)

				if not writeSuccess then
					local err = Error.new(Error.WriteFailed, property, newInstance, reason.kind)
					Log.warn(err)
				end
			end
		end

		for _, child in instance:GetChildren() do
			child.Parent = newInstance
		end

		newInstance.Parent = instance.Parent
		instance.Parent = nil

		self.tree:updateInstance(snapshot.id, newInstance)

		instance = newInstance
	end

	if snapshot.name then
		instance.Name = snapshot.name
	end

	if snapshot.properties then
		if initial then
			for property, value in snapshot.properties do
				local decodeSuccess, decodedValue = Dom.EncodedValue.decode(value)

				if not decodeSuccess then
					local err = Error.new(Error.DecodeFailed, property, value)
					Log.warn(err)

					continue
				end

				local writeSuccess, reason = Dom.writeProperty(instance, property, decodedValue)

				if not writeSuccess then
					local err = Error.new(Error.WriteFailed, property, instance, reason.kind)
					Log.warn(err)
				end
			end
		else
			for property, default in (defaultProperties or Dom.getDefaultProperties(instance.ClassName)) do
				local value = snapshot.properties[property]

				if value then
					local decodeSuccess, snapshotValue = Dom.EncodedValue.decode(value)

					if not decodeSuccess then
						local err = Error.new(Error.DecodeFailed, property, value)
						Log.warn(err)

						continue
					end

					local writeSuccess, reason = Dom.writeProperty(instance, property, snapshotValue)

					if not writeSuccess then
						local err = Error.new(Error.WriteFailed, property, instance, reason.kind)
						Log.warn(err)
					end
				else
					local _, defaultValue = Dom.EncodedValue.decode(default)
					local writeSuccess, reason = Dom.writeProperty(instance, property, defaultValue)

					if not writeSuccess then
						local err = Error.new(Error.WriteFailed, property, instance, reason.kind)
						Log.warn(err)
					end
				end
			end
		end
	end

	if not initial then
		setWaypoint("Update", instance.Name)
	end

	return instance
end

function WriteProcessor:applyRemoval(object: Types.Ref | Instance, initial: boolean?): Instance?
	Log.trace("Applying removal of", object)

	if typeof(object) == "Instance" then
		self.tree:removeByInstance(object)
		object.Parent = nil
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

		self.tree:removeById(object)
		instance.Parent = nil

		object = instance
	end

	if not initial then
		setWaypoint("Remove", (object :: Instance).Name)
	end

	return object
end

return WriteProcessor
