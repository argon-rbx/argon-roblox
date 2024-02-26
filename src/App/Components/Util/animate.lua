local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App

local Fusion = require(Argon.Packages.Fusion)
local Theme = require(App.Theme)
local Types = require(App.Types)

local Spring = Fusion.Spring

return function<T>(
	goal: Types.StateObject<T>,
	speed: Types.CanBeState<number>?,
	damping: Types.CanBeState<number>?
): Types.Spring<T>
	return Spring(goal, speed or Theme.SpringSpeed, damping or Theme.SpringDamping)
end
