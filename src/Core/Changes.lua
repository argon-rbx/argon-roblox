local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

local Types = require(script.Parent.Types)

local Changes = {}
Changes.__index = Changes

function Changes.new()
	local self = {
		additions = {} :: { Types.AddedSnapshot },
		updates = {} :: { Types.UpdatedSnapshot },
		removals = {} :: { Types.Ref | Instance },
	}

	return setmetatable(self, Changes)
end

function Changes:add(snapshot: Types.AddedSnapshot)
	table.insert(self.additions, Util.deepCopy(snapshot))
end

function Changes:update(snapshot: Types.UpdatedSnapshot)
	table.insert(self.updates, Util.deepCopy(snapshot))
end

function Changes:remove(object: Types.Ref | Instance)
	table.insert(self.removals, object)
end

function Changes:join(other: Types.Changes)
	for _, addition in ipairs(other.additions) do
		self:add(addition)
	end

	for _, update in ipairs(other.updates) do
		self:update(update)
	end

	for _, removal in ipairs(other.removals) do
		self:remove(removal)
	end
end

return Changes
