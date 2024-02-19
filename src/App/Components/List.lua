local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local App = script:FindFirstAncestor('App')

local Style = require(App.Style)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

type Props = {
	[any]: any,
}

return function(props: Props): UIListLayout
	return Hydrate(New 'UIListLayout' {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = Style.Padding,
	})(props)
end
