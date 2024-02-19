local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local App = script:FindFirstAncestor('App')
local Components = script.Parent
local Util = Components.Util

local Enums = require(App.Enums)
local Style = require(App.Style)
local Types = require(Util.Types)
local mapColor = require(Util.mapColor)

local New = Fusion.New

type Props = {
	Color: Types.CanBeState<Enums.Color | Color3>?,
	Transparency: Types.CanBeState<number>?,
	Thickness: Types.CanBeState<number>?,
	CornerRadius: Types.CanBeState<UDim>?,
}

return function(props: Props): { Instance }
	return {
		New 'UICorner' {
			CornerRadius = props.CornerRadius or Style.CornerRadius,
		},
		New 'UIStroke' {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = mapColor(props.Color, Enums.Color.BackgroundDimmed),
			Thickness = props.Thickness or Style.BorderThickness,
			Transparency = props.Transparency or 0,
		},
	}
end
