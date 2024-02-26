local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local default = require(Util.default)
local stripProps = require(Util.stripProps)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	'Padding',
	'Horizontal',
	'Vertical',
}

type Props = {
	Padding: number?,
	Horizontal: boolean?,
	Vertical: boolean?,
	[any]: any,
}

return function(props: Props): UIPadding
	local padding = props.Padding and UDim.new(0, props.Padding) or Theme.Padding
	local horizontal = default(props.Horizontal, true)
	local vertical = default(props.Vertical, true)

	return Hydrate(New 'UIPadding' {
		PaddingLeft = horizontal and padding or nil,
		PaddingRight = horizontal and padding or nil,
		PaddingTop = vertical and padding or nil,
		PaddingBottom = vertical and padding or nil,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
