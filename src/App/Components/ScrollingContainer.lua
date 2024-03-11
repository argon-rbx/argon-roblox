local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local stripProps = require(Util.stripProps)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	'ScrollBar',
}

type Props = {
	ScrollBar: boolean?,
	[any]: any,
}

return function(props: Props): ScrollingFrame
	return Hydrate(New 'ScrollingFrame' {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = props.ScrollBar and 4 or 0,
		ScrollBarImageColor3 = Theme.Colors.TextDimmed,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0),
		BorderSizePixel = 0,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
