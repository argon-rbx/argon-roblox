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
	NotSubscribed = 'Client with this ID: $1, was not subscribed to the server',
	-- HttpService
	ConnectFail = 'Failed to connect to the Argon server! Make sure the server is running and the address is correct',
	DnsResolve = 'Host name is corrupted or not found',
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
		err.message = err.message:gsub('$' .. i, Util.stringify(v))
	end

	return err
end

function Error.fromResponse(response: { [string]: any }): Error
	return Error.__new(Error.Unknown.message:gsub('$1', response.Body), 'Unknown', response)
end

function Error.fromMessage(message: string): Error
	for kind, err in pairs(Error) do
		if type(err) == 'table' and message:find(kind) and kind ~= 'Unknown' then
			return Error.__new(err.message, kind)
		end
	end

	return Error.__new(message, 'Unknown')
end

-- Convert all strings to Error objects
for kind, message in pairs(Error) do
	if type(message) == 'string' then
		Error[kind] = Error.__new(message, kind)
	end
end

return Error
