local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Util = require(Argon.Util)

local Types = require(script.Parent.Types)
local Changes = require(script.Parent.Changes)

local Processor = {}
Processor.__index = Processor

function Processor.new(tree)
	local self = {
		tree = tree,
	}

	return setmetatable(self, Processor)
end

function Processor:initialize(initialChanges: Types.Changes): Promise.TypedPromise<Types.Changes>
	return Promise.new(function(resolve, reject)
		local changes = Changes.new()

		for i, change in pairs(initialChanges) do
			local snapshot = change.Create :: Types.AddedSnapshot

			-- Skip the first change, as it's the root and needs to be processed differently
			if i == 1 then
				if snapshot.name ~= 'ROOT' then
					return reject('First change must be the root')
				end

				self.tree:insert(game, snapshot.id)

				continue
			end

			-- Hydrate initial changes
			do
				local parent = self.tree:getInstance(snapshot.parent)

				-- If parent doesn't exist it means that snapshot is a child of a new instance
				if parent then
					for _, child in parent:GetChildren() do
						if child.Name == snapshot.name and child.ClassName == snapshot.class then
							if self.tree:getId(child) then
								continue
							end

							self.tree:insert(child, snapshot.id)
							break
						end
					end
				end
			end

			-- Diff local instances with incoming snapshots
			do
				local instance = self.tree:getInstance(snapshot.id)

				-- Incoming snapshot does not exist locally
				if not instance then
					changes:add(snapshot)
					continue
				end

				-- print(initialChanges[i].Create)

				print(instance)
			end
		end

		print(changes)

		return resolve()
	end)
end

return Processor
