local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local Types = require(App.Types)
local stripProps = require(Util.stripProps)

local Border = require(Components.Border)
local Container = require(Components.Container)

local Hydrate = Fusion.Hydrate
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
	'BackgroundColor',
	'BorderColor',
}

type Props = {
	BackgroundColor: Types.CanBeState<Color3>?,
	BorderColor: Types.CanBeState<Color3>?,
	[any]: any,
}

return function(props: Props): Frame
	return Hydrate(Container {
		Size = UDim2.fromOffset(120, Theme.CompSizeY),
		BackgroundColor3 = props.BackgroundColor or Theme.Colors.Background,
		BackgroundTransparency = 0,

		[Children] = {
			Border {},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
