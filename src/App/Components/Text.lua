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
	'Font',
	'Color',
}

type Props = {
	Font: Fusion.CanBeState<Font>?,
	Color: Fusion.CanBeState<Color3>?,
	[any]: any,
}

return function(props: Props): TextLabel
	return Hydrate(New('TextLabel') {
		FontFace = props.Font or Theme.Fonts.Regular,
		TextColor3 = props.Color or Theme.Colors.Text,
		TextSize = Theme.TextSize,
		AutomaticSize = Enum.AutomaticSize.XY,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
