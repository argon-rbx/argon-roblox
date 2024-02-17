local HttpService = game:GetService('HttpService')

local plugin = script:FindFirstAncestorWhichIsA('Plugin')
local Fusion = require(plugin:FindFirstChild('Fusion', true))

local Components = script.Parent.Parent
local Util = Components.Util

local stripProps = require(Util.stripProps)
local default = require(Util.default)

local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	'Id',
	'InitialDockTo',
	'InitialEnabled',
	'ForceInitialEnabled',
	'FloatingSize',
	'MinimumSize',
}

type WidgetProps = {
	Id: string?,
	Name: string,
	InitialDockTo: Enum.InitialDockState?,
	InitialEnabled: boolean?,
	ForceInitialEnabled: boolean?,
	FloatingSize: Vector2,
	MinimumSize: Vector2,
	[any]: any,
}

return function(props: WidgetProps): DockWidgetPluginGui
	local widget = plugin:CreateDockWidgetPluginGui(
		props.Id or HttpService:GenerateGUID(),
		DockWidgetPluginGuiInfo.new(
			default(props.InitialDockTo, Enum.InitialDockState.Float),
			default(props.InitialEnabled, false),
			default(props.ForceInitialEnabled, false),
			props.FloatingSize.X,
			props.FloatingSize.Y,
			props.MinimumSize.X,
			props.MinimumSize.Y
		)
	)

	props.Title = props.Name

	if typeof(props.Enabled) == 'table' and props.Enabled.kind == 'Value' then
		props.Enabled:set(widget.Enabled)
	end

	return Hydrate(widget)(stripProps(props, COMPONENT_ONLY_PROPS))
end
