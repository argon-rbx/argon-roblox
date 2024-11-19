local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Assets = require(App.Assets)
local Theme = require(App.Theme)
local stripProps = require(Util.stripProps)

local Image = require(Components.Image)

local Tween = Fusion.Tween
local Value = Fusion.Value
local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	"Duration",
}

type Props = {
	Duration: number?,
	[any]: any,
}

return function(props: Props): ImageLabel
	local rotation = Value(0)

	task.defer(function()
		rotation:set(360)
	end)

	return Hydrate(Image {
		Size = UDim2.fromOffset(Theme.CompSizeY.Medium, Theme.CompSizeY.Medium),
		Image = Assets.Icons.Spinner,
		ImageColor3 = Theme.Colors.Text,
		Rotation = Tween(
			rotation,
			TweenInfo.new(props.Duration or 1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
		),
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
