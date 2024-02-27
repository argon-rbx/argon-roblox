local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local Spring = Fusion.Spring

return function<T>(
	goal: Fusion.StateObject<T>,
	speed: Fusion.CanBeState<number>?,
	damping: Fusion.CanBeState<number>?
): Fusion.Spring<T>
	return Spring(goal, speed or Theme.SpringSpeed, damping or Theme.SpringDamping)
end
