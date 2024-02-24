local Argon = script:FindFirstAncestor('Argon')
local App = script:FindFirstAncestor('App')

local Fusion = require(Argon.Packages.Fusion)

local Enums = require(App.Enums)
local Types = require(App.Types)
local ThemeProvider = require(App.ThemeProvider)

local Computed = Fusion.Computed

return function(color: Types.CanBeState<Enums.Color | Color3>?, default: Enums.Color): Types.Computed<Color3>
	return Computed(function(use)
		local color = use(color)

		if color then
			if typeof(color) == 'Color3' then
				return color
			else
				return use(ThemeProvider:GetColor(color))
			end
		else
			return use(ThemeProvider:GetColor(default))
		end
	end)
end
