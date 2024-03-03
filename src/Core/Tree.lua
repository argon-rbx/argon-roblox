local Types = require(script.Parent.Types)

local Tree = {}

function Tree.new()
	local self = setmetatable({}, { __index = Tree })

	self.instanceMap = {}
	self.idMap = {}

	return self
end

function Tree:insert(instance: Instance, id: Types.Ref)
	self.instanceMap[id] = instance
	self.idMap[instance] = id
end

function Tree:getByInstance(instance: Instance): Types.Ref?
	return self.idMap[instance]
end

function Tree:getById(id: Types.Ref): Instance?
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
