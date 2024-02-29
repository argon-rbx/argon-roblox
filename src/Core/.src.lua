local Core = {}

function Core.new(client)
	local self = setmetatable({}, { __index = Core })

	self.client = client

	return self
end

function Core:init() end

function Core:connect() end

return Core
