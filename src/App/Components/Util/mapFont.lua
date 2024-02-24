local Argon = script:FindFirstAncestor('Argon')
local App = script:FindFirstAncestor('App')

local Fusion = require(Argon.Packages.Fusion)

local Enums = require(App.Enums)
local Style = require(App.Style)
local Types = require(App.Types)

local Computed = Fusion.Computed

return function(font: Types.CanBeState<Enums.Font>?, default: Enums.Font): Types.Computed<Font>
	return Computed(function(use)
		local font = use(font)

		if font then
			return Style.Fonts[Enums:GetName(Enums.Font, font)]
		else
			return Style.Fonts[Enums:GetName(Enums.Font, default)]
		end
	end)
end
