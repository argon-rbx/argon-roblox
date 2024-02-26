local HttpService = game:GetService('HttpService')

local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

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
	FloatingSize: Vector2?,
	MinimumSize: Vector2,
	[any]: any,
}

return function(props: WidgetProps): DockWidgetPluginGui
	local floatingSize = props.FloatingSize or props.MinimumSize

	local widget = plugin:CreateDockWidgetPluginGui(
		props.Id or HttpService:GenerateGUID(),
		DockWidgetPluginGuiInfo.new(
			props.InitialDockTo or Enum.InitialDockState.Float,
			default(props.InitialEnabled, false),
			default(props.ForceInitialEnabled, false),
			floatingSize.X,
			floatingSize.Y,
			props.MinimumSize.X,
			props.MinimumSize.Y
		)
	)

	props.Title = props.Name

	return Hydrate(widget)(stripProps(props, COMPONENT_ONLY_PROPS))
end
