export type Error = {
	message: string,
	kind: string,
	data: any?,
}

local Error = {
	Unknown = 'Unknown Core error: $1',
	-- Initial prompts
	GameId = 'Current GameId: $1 does not match the server game_id: $2',
	PlaceIds = 'Current PlaceId: $1 is not inluded in the server place_ids list: $2',
	TooManyChanges = 'There are $1 additions, $2 updates, $3 deletions compared to the server',
	-- Process errors
	DecodeFailed = 'Failed to decode snapshot property: $1 with value: $2',
	ReadFailed = 'Failed to read property: $1 from instance: $2',
	WriteFailed = 'Failed to write property: $1 to instance: $2',
	InstanceNotFound = 'Instance: $1 does not exist in the tree',
}

function Error.__new(message: string, kind: string, data: any?): Error
	local err = setmetatable({
		message = message,
		kind = kind,
		data = data,
	}, {
		__eq = function(self, other: Error): boolean
			return self.kind == other.kind
		end,
	})

	return err
end

function Error.new(err: Error, ...): Error
	err = table.clone(err)

	for i, v in pairs({ ... }) do
		err.message = err.message:gsub('$' .. i, v)
	end

	return err
end

-- Convert all strings to Error objects
for kind, message in pairs(Error) do
	if type(message) == 'string' then
		Error[kind] = Error.__new(message, kind)
	end
end

return Error
