local HttpService = game:GetService('HttpService')

local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local Error = require(script.Parent.Error)

type Response = {
	Body: string,
	Headers: { [string]: string },
	StatusCode: number,
	StatusMessage: string,
	Success: boolean,
	json: () -> { [string]: any },
}

local function methodify(response: { [string]: any }): any
	return setmetatable(response, {
		__index = {
			json = function(self)
				return HttpService:JSONDecode(self.Body)
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
					['Content-Type'] = 'application/json',
				},
				Body = body and HttpService:JSONEncode(body) or nil,
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

function Http.get(url)
	return request('GET', url)
end

function Http.post(url, body)
	return request('POST', url, body)
end

return Http
