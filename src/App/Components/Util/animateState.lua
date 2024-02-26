local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local Types = require(App.Types)

local Spring = Fusion.Spring
local Computed = Fusion.Computed

return function(
	goal: Types.StateObject<Color3>,
	state: Types.Computed<Enum.GuiState>,
	speed: Types.CanBeState<number>?,
	damping: Types.CanBeState<number>?
): Types.Spring<Color3>
	return Spring(
		Computed(function(use)
			local goal = use(goal)
			local state = use(state)

			local isDark = use(Theme.IsDark)
			local h, s, v = goal:ToHSV()

			if state == Enum.GuiState.Hover then
				return Color3.fromHSV(h, s, v * (isDark and 1.3 or 0.9))
			elseif state == Enum.GuiState.Press then
				return Color3.fromHSV(h, s, v * (isDark and 1.5 or 0.8))
			else
				return goal
			end
		end),
		speed or Theme.SpringSpeed,
		damping or Theme.SpringDamping
	)
end
