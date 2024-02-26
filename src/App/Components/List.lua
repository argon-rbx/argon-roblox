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
	'Padding',
}

type Props = {
	Padding: number?,
	[any]: any,
}

return function(props: Props): UIListLayout
	return Hydrate(New 'UIListLayout' {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = props.Padding and UDim.new(0, props.Padding) or Theme.ListSpacing,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
