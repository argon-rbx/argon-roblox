local plugin = script:FindFirstAncestorWhichIsA('Plugin')
local Fusion = require(plugin:FindFirstChild('Fusion', true))

local Components = script.Parent.Parent
local Util = Components.Util

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
