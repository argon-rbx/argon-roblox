local Argon = script:FindFirstAncestor('Argon')

local Types = require(Argon.Types)

local Meta = {}
Meta.__index = Meta

function Meta.new(): Types.Meta
	local self = setmetatable({}, Meta)

	self.keepUnknowns = false

	return self
end

return Meta
