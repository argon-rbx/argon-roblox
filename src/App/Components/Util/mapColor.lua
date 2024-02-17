local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local Enums = require(script.Parent.Enums)
local Types = require(script.Parent.Types)
local ThemeProvider = require(script.Parent.ThemeProvider)

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
