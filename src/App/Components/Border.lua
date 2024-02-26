local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local Types = require(App.Types)

local New = Fusion.New

type Props = {
	Color: Types.CanBeState<Color3>?,
	Transparency: Types.CanBeState<number>?,
	Thickness: Types.CanBeState<number>?,
	CornerRadius: Types.CanBeState<UDim>?,
}

return function(props: Props): { Instance }
	return {
		New 'UICorner' {
			CornerRadius = props.CornerRadius or Theme.CornerRadius,
		},
		New 'UIStroke' {
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = props.Color or Theme.Colors.Border,
			Thickness = props.Thickness or Theme.BorderThickness,
			Transparency = props.Transparency or 0,
		},
	}
end
