local Argon = script:FindFirstAncestor('Argon')

local Types = require(Argon.Types)

local Tree = {}
Tree.__index = Tree

function Tree.new()
	local self = {
		instanceMap = {},
		metaMap = {},
		idMap = {},
	}

	return setmetatable(self, Tree)
end

function Tree:insertInstance(instance: Instance, id: Types.Ref, meta: Types.Meta)
	self.instanceMap[id] = instance
	self.idMap[instance] = id

	self:insertMeta(id, meta)
end

function Tree:updateInstance(id: Types.Ref, instance: Instance)
	local old = self.instanceMap[id]

	if not old then
		return
	end

	self.idMap[old] = nil

	self.instanceMap[id] = instance
	self.idMap[instance] = id
end

function Tree:getId(instance: Instance): Types.Ref?
	return self.idMap[instance]
end

function Tree:getInstance(id: Types.Ref): Instance?
	return self.instanceMap[id]
end

function Tree:removeByInstance(instance: Instance): Types.Ref?
	local id = self.idMap[instance]

	if not id then
		return nil
	end

	self.instanceMap[id] = nil
	self.idMap[instance] = nil

	self:removeMeta(id)

	return id
end

function Tree:removeById(id: Types.Ref): Instance?
	local instance = self.instanceMap[id]

	if not instance then
		return nil
	end

	self.instanceMap[id] = nil
	self.idMap[instance] = nil

	self:removeMeta(id)

	return instance
end

function Tree:insertMeta(id: Types.Ref, meta: Types.Meta)
	self.metaMap[id] = meta
end

function Tree:getMeta(id: Types.Ref): Types.Meta?
	return self.metaMap[id]
end

function Tree:updateMeta(id: Types.Ref, meta: Types.Meta)
	local old = self.metaMap[id]

	if not old then
		return
	end

	self.metaMap[id] = meta
end

function Tree:removeMeta(id: Types.Ref): Types.Meta?
	local meta = self.metaMap[id]

	self.metaMap[id] = nil

	return meta
end

return Tree
