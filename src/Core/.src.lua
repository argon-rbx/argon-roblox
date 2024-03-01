local Argon = script:FindFirstAncestor('Argon')

local Promise = require(Argon.Packages.Promise)

local ClientError = require(Argon.Client.Error)

export type Status = 'Connected' | 'Disconnected' | 'Error'

local Core = {}

function Core.new(client)
	local self = setmetatable({}, { __index = Core })

	self.project = nil
	self.client = client
	self.status = 'Disconnected'

	return self
end

function Core:init(ignoreIds: boolean): Promise.Promise
	return self.client
		:subscribe(ignoreIds)
		:andThen(function(project)
			self.client:readAll():andThen(function(data)
				self.project = project

				print(data)

				return project
			end)
		end)
		:catch(function(err)
			if ClientError.is(err, ClientError.GameId) or ClientError.is(err, ClientError.PlaceIds) then
				-- TODO: prompt user

				return self:init(true)
			else
				return Promise.reject(err)
			end
		end)
end

return Core
