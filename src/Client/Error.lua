local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

export type Error = {
	message: string,
	kind: string,
	data: any?,
}

local Error = {
	Unknown = 'Unknown HTTP error: $1',
	-- Argon client
	AlreadySubscribed = 'Client with this ID: $1, already subscribed to the server',
	GameId = 'Current GameId: $1 does not match the server game_id: $2',
	PlaceIds = 'Current PlaceId: $1 is not inluded in the server place_ids list: $2',
	-- HttpService
	ConnectFail = 'Failed to connect to the Argon server! Make sure the server is running and the address is correct',
	DnsResolve = 'Host name is corrupted or not found',
}

function Error.new(kind: string, ...): Error
	local message = kind

	for i, v in pairs({ ... }) do
		message = message:gsub('$' .. i, v)
	end

	return {
		message = message,
		kind = Util.findDictionary(Error, kind),
	}
end

function Error.fromResponse(response: { [string]: any }): Error
	return {
		message = Error.Unknown:gsub('$1', response.Body),
		kind = 'Unknown',
		data = response,
	}
end

function Error.fromMessage(message: string): Error
	for err, msg in pairs(Error) do
		if type(msg) == 'string' and message:find(err) and err ~= 'Unknown' then
			return {
				message = msg,
				kind = err,
			}
		end
	end

	return {
		message = message,
		kind = 'Unknown',
	}
end

function Error.is(err: Error, kind: string): boolean
	local key = Util.findDictionary(Error, kind)
	return err.kind == key
end

return Error
