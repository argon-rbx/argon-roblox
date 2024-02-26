local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

type Props = {
	[any]: any,
}

return function(props: Props): UIPadding
	return Hydrate(New 'UIPadding' {
		PaddingBottom = Theme.Padding,
		PaddingLeft = Theme.Padding,
		PaddingRight = Theme.Padding,
		PaddingTop = Theme.Padding,
	})(props)
end
