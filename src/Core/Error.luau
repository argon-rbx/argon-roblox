local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

export type Error = {
	message: string,
	kind: string,
}

local Error = {
	Unknown = 'Unknown Core error: $1',
	-- Initial prompts
	GameId = 'Current GameId: $1 does not match the server gameId: $2',
	PlaceIds = 'Current PlaceId: $1 is not inluded in the server placeIds: $2',
	Version = 'Client version: $1 is not compatible with the server version: $2',
	TooManyChanges = 'There are $1 additions, $2 updates, $3 deletions compared to the server',
	Terminated = 'Terminated connection by the user',
	-- Core errors
	UnknownEvent = 'Received an unknown event from the server: $1, with data: $2',
	Disconnected = 'Disconnected from the server: $1',
	-- Process errors
	DecodeFailed = 'Failed to decode snapshot property: $1 with value: $2',
	EncodeFailed = 'Failed to encode snapshot property: $1 with value: $2',
	ReadFailed = 'Failed to read property: $1 from instance: $2, reason: $3',
	WriteFailed = 'Failed to write property: $1 for instance: $2, reason: $3',
	NoInstanceAdd = 'Tried to add an instance whose parent that does not exist in the tree: $1',
	NoInstanceUpdate = 'Tried to update an instance that does not exist in the tree: $1',
	NoInstanceRemove = 'Tried to remove an instance that does not exist in the tree: $1',
	NotCreatable = 'Tried to create an instance of class: $1 that is not creatable',
	NotRemovable = 'Tried to remove an instance of class: $1 that is not removable',
	HydrationFailed = 'Failed to hydrate root service, snapshot: $1',
	MeshLoadFailed = 'Failed to load MeshPart: $1. If you just updated Roblox Studio, please restart Argon session!',
}

function Error.__new(message: string, kind: string): Error
	local err = setmetatable({
		message = message,
		kind = kind,
	}, Error)

	return err
end

function Error.new(err: Error, ...): Error
	err = table.clone(err)

	for i, v in pairs({ ... }) do
		err.message = err.message:gsub('$' .. i, Util.stringify(v))
	end

	return err
end

function Error:__eq(other: Error): boolean
	return self.kind == other.kind
end

function Error:__tostring(): string
	return self.message
end

-- Convert all strings to Error objects
for kind, message in pairs(Error) do
	if type(message) == 'string' then
		Error[kind] = Error.__new(message, kind)
	end
end

return Error
