local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)
local Config = require(Argon.Config)

local Assets = require(App.Assets)
local Theme = require(App.Theme)
local filterHost = require(Util.filterHost)
local filterPort = require(Util.filterPort)

local TextButton = require(Components.TextButton)
local IconButton = require(Components.IconButton)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Input = require(Components.Input)
local List = require(Components.List)
local Text = require(Components.Text)
local Box = require(Components.Box)

local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed
local Children = Fusion.Children

type Props = {
	App: { [string]: any },
	Host: string,
	Port: number,
}

return function(props: Props): { Instance }
	local hostInput = Value(props.Host ~= Config:getDefault("Host") and props.Host or "")
	local portInput = Value(props.Port ~= Config:getDefault("Port") and props.Port or "")

	local hostFocused = Value(false)
	local portFocused = Value(false)

	return {
		List {},
		Box {
			Size = UDim2.new(1, 0, 0, Theme.CompSizeY.Large),
			AutomaticSize = Enum.AutomaticSize.None,
			BorderColor = Computed(function(use)
				if use(hostFocused) or use(portFocused) then
					return use(Theme.Colors.Brand)
				else
					return use(Theme.Colors.Border)
				end
			end),

			[Children] = {
				List {
					Spacing = 4,
					FillDirection = Enum.FillDirection.Horizontal,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				},
				Input {
					Size = UDim2.fromScale(0.75, 1),
					Font = Theme.Fonts.Mono,
					PlaceholderText = "localhost",
					Text = hostInput,

					Started = function()
						hostFocused:set(true)
					end,

					Changed = function(text)
						hostInput:set(filterHost(text))
					end,

					Finished = function(host)
						hostFocused:set(false)
						props.App:setHost(host ~= "" and host or Config:getDefault("Host"))
					end,

					[Children] = {
						New "UIFlexItem" {
							FlexMode = Enum.UIFlexMode.Fill,
						},
					},
				},
				Text {
					AutomaticSize = Enum.AutomaticSize.XY,
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(0, 0.5),
					Text = ":",
					Font = Theme.Fonts.Mono,
					Color = Theme.Colors.TextDimmed,
				},
				Input {
					AutomaticSize = Enum.AutomaticSize.X,
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromScale(0, 1),
					Font = Theme.Fonts.Mono,
					PlaceholderText = "8000",
					Text = portInput,

					Started = function(text)
						portFocused:set(true)
					end,

					Changed = function(text)
						portInput:set(filterPort(text))
					end,

					Finished = function(port)
						portFocused:set(false)
						props.App:setPort(port ~= "" and tonumber(port) or Config:getDefault("Port"))
					end,
				},
				Padding {
					Padding = 10,
					Vertical = false,
				},
			},
		},
		Container {
			Size = UDim2.fromScale(1, 0),
			[Children] = {
				List {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				TextButton {
					Solid = true,
					LayoutOrder = 2,
					Text = "Connect",
					Activated = function()
						props.App:connect()
					end,
				},
				IconButton {
					Icon = Assets.Icons.Settings,
					BackgroundActive = Computed(function(use)
						return use(props.App.settingsWidget) ~= nil
					end),
					Activated = function()
						props.App:settings()
					end,
					LayoutOrder = 1,
				},
				IconButton {
					Icon = Assets.Icons.Help,
					BackgroundActive = Computed(function(use)
						return use(props.App.helpWidget) ~= nil
					end),
					Activated = function()
						props.App:help()
					end,
				},
			},
		},
	}
end
