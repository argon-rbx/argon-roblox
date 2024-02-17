local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local Components = script.Parent
local Util = Components.Util

local Types = require(Util.Types)
local Enums = require(Util.Enums)
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
		Text = '',
		Size = UDim2.fromOffset(200, 60),
		AutoButtonColor = false,
		BackgroundColor3 = mapColor(props.BackgroundColor, Enums.Color.Primary),

		[Children] = {
			Border {
				Color = mapColor(props.BorderColor, Enums.Color.Dimmed),
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
