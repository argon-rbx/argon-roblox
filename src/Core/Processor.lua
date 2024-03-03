local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Types = require(script.Parent.Types)

local Processor = {}

function Processor.new(tree)
	local self = setmetatable({}, { __index = Processor })

	self.tree = tree

	return self
end

function Processor:initialize(changes: Types.Changes): Promise.Promise
	return Promise.new(function(resolve, reject)
		for i, change in pairs(changes) do
			local snapshot = change.Create :: Types.Snapshot

			-- Skip the first change, as it's the root and needs to be processed differently
			if i == 1 then
				if snapshot.name ~= 'ROOT' then
					reject('First change must be the root')
				end

				self.tree:insert(game, snapshot.id)

				continue
			end

			self:hydrate(snapshot)
		end

		print(self.tree)

		resolve('Changes processed successfully')
	end)
end

function Processor:hydrate(snapshot: Types.Snapshot): Promise.Promise
	return Promise.new(function(resolve, reject)
		local parent = self.tree:getById(snapshot.parent)

		if not parent then
			return reject(`Failed to hydrate snapshot: {snapshot} - parent does not exist`)
		end

		-- TODO

		return resolve('Hydrated successfully')
	end)
end

return Processor
