local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local Components = script.Parent
local Util = Components.Util

local Enums = require(Util.Enums)
local Types = require(Util.Types)
local Defaults = require(Util.Defaults)
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
			CornerRadius = props.CornerRadius or Defaults.CornerRadius,
		},
		New 'UIStroke' {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = mapColor(props.Color, Enums.Color.Dimmed),
			Thickness = props.Thickness or Defaults.BorderThickness,
			Transparency = props.Transparency or 0,
		},
	}
end
