local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Assets = require(App.Assets)
local Theme = require(App.Theme)
local Types = require(App.Types)
local stripProps = require(Util.stripProps)
local isState = require(Util.isState)

local IconButton = require(Components.IconButton)

local Value = Fusion.Value
local peek = Fusion.peek
local Hydrate = Fusion.Hydrate
local Computed = Fusion.Computed

local COMPONENT_ONLY_PROPS = {
	'Changed',
	'Value',
}

type Props = {
	Changed: ((value: boolean) -> nil)?,
	Value: Types.CanBeState<boolean>?,
	[any]: any,
}

return function(props: Props): TextButton
	local isChecked = isState(props.Value) and props.Value or Value(props.Value or false)

	return Hydrate(IconButton {
		Size = UDim2.fromOffset(Theme.CompSizeY - 6, Theme.CompSizeY - 6),
		Solid = isChecked,
		Icon = Computed(function(use)
			return use(isChecked) and Assets.Icons.Checkmark or ''
		end),

		Activated = function()
			isChecked:set(not peek(isChecked))

			if props.Changed then
				props.Changed(peek(isChecked))
			end
		end,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
