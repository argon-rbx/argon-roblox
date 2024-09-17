--!strict
local Argon = script:FindFirstAncestor("Argon")

local Log = require(Argon.Log)

type ExecutorImpl = {
	__index: ExecutorImpl,
	new: () -> Executor,
	execute: (self: Executor, code: string) -> (),
}

type Executor = typeof(setmetatable(
	{} :: {
		thread: thread?,
	},
	{} :: ExecutorImpl
))

local Executor: ExecutorImpl = {} :: ExecutorImpl
Executor.__index = Executor

function Executor.new()
	return setmetatable({
		thread = nil,
	}, Executor)
end

function Executor:execute(code)
	if self.thread then
		task.cancel(self.thread)
		self.thread = nil
	end

	self.thread = task.spawn(function()
		local success, result = pcall(function()
			local fn = loadstring(code)

			if fn then
				fn()
			else
				Log.error("Code execution error: 'loadstring' did not return a function!")
			end
		end)

		if success then
			Log.trace("Executed code successfully")
		else
			Log.warn("Failed to execute code:", result)
		end

		self.thread = nil
	end)
end

return Executor
