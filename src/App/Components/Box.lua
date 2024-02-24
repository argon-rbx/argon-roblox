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

local Border = require(Components.Border)
local Container = require(Components.Container)

local Hydrate = Fusion.Hydrate
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
	'BackgroundColor',
	'BorderColor',
}

type Props = {
	BackgroundColor: Types.CanBeState<Enums.Color | Color3>?,
	BorderColor: Types.CanBeState<Enums.Color | Color3>?,
	[any]: any,
}

return function(props: Props): Frame
	return Hydrate(Container {
		Size = UDim2.fromOffset(120, Style.CompSizeY),
		BackgroundColor3 = mapColor(props.BackgroundColor, Enums.Color.Background),
		BackgroundTransparency = 0,

		[Children] = {
			Border {
				Color = mapColor(props.BorderColor, Enums.Color.Border),
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
