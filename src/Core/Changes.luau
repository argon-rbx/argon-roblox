local Argon = script:FindFirstAncestor('Argon')

local Types = require(Argon.Types)

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

function Changes:add(snapshot: Types.Snapshot, parent: Types.Ref?)
	local addedSnapshot = snapshot
	addedSnapshot.parent = parent or addedSnapshot.parent

	table.insert(self.additions, addedSnapshot)
end

function Changes:update(snapshot: Types.UpdatedSnapshot)
	table.insert(self.updates, snapshot)
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

function Changes:total(): number
	return #self.additions + #self.updates + #self.removals
end

function Changes:isEmpty(): boolean
	return self:total() == 0
end

function Changes.Total(changes: Types.Changes): number
	return #changes.additions + #changes.updates + #changes.removals
end

return Changes
