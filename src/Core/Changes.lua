local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

local Types = require(script.Parent.Types)

local Changes = {}
Changes.__index = Changes

function Changes.new()
	local self = {
		additions = {} :: { Types.AddedSnapshot },
		updates = {} :: { Types.UpdatedSnapshot },
		removals = {} :: { Types.RemovedSnapshot },
	}

	return setmetatable(self, Changes)
end

function Changes:add(snapshot: Types.AddedSnapshot)
	table.insert(self.additions, Util.deepCopy(snapshot))
end

function Changes:update(snapshot: Types.UpdatedSnapshot)
	table.insert(self.updates, Util.deepCopy(snapshot))
end

function Changes:remove(id: Types.Ref)
	table.insert(self.removals, { id = id })
end

return Changes
