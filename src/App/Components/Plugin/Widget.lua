local HttpService = game:GetService('HttpService')

local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local stripProps = require(Util.stripProps)
local isState = require(Util.isState)
local default = require(Util.default)

local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	'Id',
	'InitialDockTo',
	'InitialEnabled',
	'OverrideEnabled',
	'FloatingSize',
	'MinimumSize',
	'Closed',
}

type WidgetProps = {
	Id: string?,
	Name: Fusion.CanBeState<string>,
	InitialDockTo: Enum.InitialDockState?,
	InitialEnabled: boolean?,
	OverrideEnabled: boolean?,
	FloatingSize: Vector2?,
	MinimumSize: Vector2,
	Closed: (() -> nil)?,
	[any]: any,
}

return function(props: WidgetProps): DockWidgetPluginGui
	local floatingSize = props.FloatingSize or props.MinimumSize

	local widget = plugin:CreateDockWidgetPluginGui(
		props.Id or HttpService:GenerateGUID(),
		DockWidgetPluginGuiInfo.new(
			props.InitialDockTo or Enum.InitialDockState.Float,
			default(props.InitialEnabled, true),
			default(props.OverrideEnabled, false),
			floatingSize.X,
			floatingSize.Y,
			props.MinimumSize.X,
			props.MinimumSize.Y
		)
	)

	if isState(props.Enabled) then
		props.Enabled:set(widget.Enabled)
	end

	if props.Closed then
		widget:BindToClose(props.Closed)
	end

	widget.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	props.Title = props.Name

	return Hydrate(widget)(stripProps(props, COMPONENT_ONLY_PROPS))
end
