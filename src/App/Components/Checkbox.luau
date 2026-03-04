local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Assets = require(App.Assets)
local Theme = require(App.Theme)
local stripProps = require(Util.stripProps)
local isState = require(Util.isState)

local IconButton = require(Components.IconButton)

local Value = Fusion.Value
local peek = Fusion.peek
local Hydrate = Fusion.Hydrate
local Computed = Fusion.Computed

local COMPONENT_ONLY_PROPS = {
	"Changed",
	"Value",
	"Placeholder",
}

type Props = {
	Changed: ((value: boolean) -> ())?,
	Value: Fusion.CanBeState<boolean>?,
	Placeholder: Fusion.CanBeState<boolean>?,
	[any]: any,
}

return function(props: Props): TextButton
	local value = isState(props.Value) and props.Value or Value(props.Value or false)
	local placeholder = isState(props.Placeholder) and props.Placeholder or Value(props.Placeholder or false)

	return Hydrate(IconButton {
		Size = UDim2.fromOffset(Theme.CompSizeY.Medium, Theme.CompSizeY.Medium),
		Solid = value,
		Blending = false,
		Icon = Computed(function(use)
			return if use(value) and use(placeholder) or use(placeholder) then Assets.Icons.Checkmark else ""
		end),
		Activated = function()
			value:set(not peek(value))

			if props.Changed then
				props.Changed(peek(value))
			end
		end,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
