local HttpService = game:GetService("HttpService")

local Argon = script:FindFirstAncestor("Argon")

local Promise = require(Argon.Packages.Promise)

local Error = require(script.Parent.Error)
local Msgpack = require(script.Parent.Msgpack)

type Response = {
	Body: string,
	Headers: { [string]: string },
	StatusCode: number,
	StatusMessage: string,
	Success: boolean,
	decode: () -> { [string]: any },
}

local function methodify(response: { [string]: any }): any
	return setmetatable(response, {
		__index = {
			decode = function(self)
				return Msgpack.decode(self.Body)
			end,
		},
	})
end

local function request(method: string, url: string, body: { [string]: any }?): Promise.TypedPromise<Response>
	return Promise.new(function(resolve, reject)
		local success, response = pcall(function()
			return HttpService:RequestAsync({
				Url = url,
				Method = method,
				Headers = {
					["Content-Type"] = "application/msgpack",
				},
				Body = body and Msgpack.encode(body) or nil,
			})
		end)

		if success then
			if response.Success then
				resolve(methodify(response))
			else
				reject(Error.fromResponse(response))
			end
		else
			reject(Error.fromMessage(response))
		end
	end)
end

local Http = {}

function Http.get(url: string)
	return request("GET", url)
end

function Http.post(url: string, body: { [string]: any }?)
	return request("POST", url, body)
end

return Http
