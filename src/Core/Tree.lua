local Types = require(script.Parent.Types)

local Tree = {}
Tree.__index = Tree

function Tree.new()
	local self = {
		instanceMap = {},
		idMap = {},
	}

	return setmetatable(self, Tree)
end

function Tree:insert(instance: Instance, id: Types.Ref)
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

	return id
end

function Tree:removeById(id: Types.Ref): Instance?
	local instance = self.instanceMap[id]

	if not instance then
		return nil
	end

	self.instanceMap[id] = nil
	self.idMap[instance] = nil

	return instance
end

return Tree
