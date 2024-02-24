local Argon = script:FindFirstAncestor('Argon')
local App = script:FindFirstAncestor('App')
local Components = script.Parent
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Enums = require(App.Enums)
local Style = require(App.Style)
local Types = require(App.Types)
local stripProps = require(Util.stripProps)
local mapColor = require(Util.mapColor)
local mapFont = require(Util.mapFont)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	'Font',
	'Color',
	'PlaceholderColor',
}

type Props = {
	Font: Types.CanBeState<Enums.Font>?,
	Color: Types.CanBeState<Enums.Color | Color3>?,
	PlaceholderColor: Types.CanBeState<Enums.Color | Color3>?,
	[any]: any,
}

return function(props: Props): TextBox
	return Hydrate(New('TextBox') {
		FontFace = mapFont(props.Font, Enums.Font.Default),
		TextColor3 = mapColor(props.Color, Enums.Color.Text),
		PlaceholderColor3 = mapColor(props.PlaceholderColor, Enums.Color.TextDimmed),
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = Enum.AutomaticSize.XY,
		TextSize = Style.TextSize,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
