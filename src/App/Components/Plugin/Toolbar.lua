local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')
local Components = script.Parent.Parent
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local stripProps = require(Util.stripProps)

local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	'Name',
}

type Props = {
	Name: string,
	[any]: any,
}

return function(props: Props): PluginToolbar
	return Hydrate(plugin:CreateToolbar(props.Name))(stripProps(props, COMPONENT_ONLY_PROPS))
end
