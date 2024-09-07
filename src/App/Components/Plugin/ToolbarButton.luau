local plugin = script:FindFirstAncestorWhichIsA("Plugin")

local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local stripProps = require(Util.stripProps)
local isState = require(Util.isState)

local Hydrate = Fusion.Hydrate
local Observer = Fusion.Observer
local peek = Fusion.peek

local COMPONENT_ONLY_PROPS = {
	"Toolbar",
	"Name",
	"ToolTip",
	"Image",
}

type ToolbarButtonProps = {
	Toolbar: PluginToolbar,
	Name: string,
	ToolTip: string,
	Image: Fusion.CanBeState<string>,
	[any]: any,
}

return function(props: ToolbarButtonProps): PluginToolbarButton
	local button = props.Toolbar:CreateButton(props.Name, props.ToolTip, peek(props.Image))
	button.ClickableWhenViewportHidden = true

	if isState(props.Image) then
		plugin.Unloading:Once(Observer(props.Image):onChange(function()
			button.Icon = peek(props.Image)
		end))
	end

	return Hydrate(button)(stripProps(props, COMPONENT_ONLY_PROPS))
end
