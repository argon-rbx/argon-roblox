local Argon = script:FindFirstAncestor('Argon')

local Fusion = require(Argon.Packages.Fusion)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

type Props = {
	[any]: any,
}

return function(props: Props): ScrollingFrame
	return Hydrate(New 'ScrollingFrame' {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0),
		BorderSizePixel = 0,
	})(props)
end
