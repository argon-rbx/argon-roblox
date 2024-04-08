local Argon = script:FindFirstAncestor('Argon')

local Log = require(Argon.Log)

-- Temporary fix for Luau LSP
local load = loadstring

local Executor = {}
Executor.__index = Executor

function Executor.new()
	local self = setmetatable({}, Executor)

	self.thread = nil

	return self
end

function Executor:execute(code: string)
	if self.thread then
		task.cancel(self.thread)
		self.thread = nil
	end

	self.thread = task.spawn(function()
		local success, result = pcall(load(code))

		if success then
			Log.trace('Executed code successfully')
		else
			Log.warn('Failed to execute code:', result)
		end

		self.thread = nil
	end)
end

return Executor
