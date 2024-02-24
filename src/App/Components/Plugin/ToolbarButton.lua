local Argon = script:FindFirstAncestor('Argon')
local Components = script.Parent.Parent
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local stripProps = require(Util.stripProps)

local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	'Toolbar',
	'Name',
	'ToolTip',
	'Image',
}

type ToolbarButtonProps = {
	Toolbar: PluginToolbar,
	Name: string,
	ToolTip: string,
	Image: string,
	[any]: any,
}

return function(props: ToolbarButtonProps): PluginToolbarButton
	return Hydrate(props.Toolbar:CreateButton(props.Name, props.ToolTip, props.Image))(
		stripProps(props, COMPONENT_ONLY_PROPS)
	)
end
