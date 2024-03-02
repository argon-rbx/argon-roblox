export type Error = {
	message: string,
	kind: string,
	data: any?,
}

local Error = {
	Unknown = 'Unknown Core error: $1',
	GameId = 'Current GameId: $1 does not match the server game_id: $2',
	PlaceIds = 'Current PlaceId: $1 is not inluded in the server place_ids list: $2',
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
for kind, msg in pairs(Error) do
	if type(msg) == 'string' then
		Error[kind] = Error.__new(msg, kind)
	end
end

return Error
