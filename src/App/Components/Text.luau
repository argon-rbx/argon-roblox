local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local stripProps = require(Util.stripProps)

local New = Fusion.New
local Hydrate = Fusion.Hydrate
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
	"Font",
	"Color",
	"Scaled",
}

type Props = {
	Font: Fusion.CanBeState<Font>?,
	Color: Fusion.CanBeState<Color3>?,
	Scaled: boolean?,
	[any]: any,
}

return function(props: Props): TextLabel
	return Hydrate(New("TextLabel") {
		FontFace = props.Font or Theme.Fonts.Regular,
		TextColor3 = props.Color or Theme.Colors.Text,
		TextSize = Theme.TextSize.Large,
		AutomaticSize = props.Scaled and Enum.AutomaticSize.None or Enum.AutomaticSize.XY,
		TextXAlignment = Enum.TextXAlignment.Left,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextScaled = props.Scaled,

		[Children] = props.Scaled and New("UITextSizeConstraint") {
			MaxTextSize = props.TextSize or Theme.TextSize.Large,
		} or nil,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
