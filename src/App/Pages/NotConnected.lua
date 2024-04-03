local Argon = script:FindFirstAncestor('Argon')
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

local Value = Fusion.Value
local Children = Fusion.Children

type Props = {
	App: { [string]: any },
	Host: string,
	Port: number,
}

return function(props: Props): { Instance }
	local hostInput = Value(props.Host ~= Config:getDefault('Host') and props.Host or '')
	local portInput = Value(props.Port ~= Config:getDefault('Port') and props.Port or '')

	return {
		List {},
		Box {
			Size = UDim2.new(1, 0, 0, Theme.CompSizeY.Large),
			[Children] = {
				Input {
					Size = UDim2.fromScale(0.75, 1),
					Font = Theme.Fonts.Mono,
					PlaceholderText = 'localhost',
					Text = hostInput,
					Scaled = true,

					Changed = function(text)
						hostInput:set(filterHost(text))
					end,

					Finished = function(host)
						props.App:setHost(host ~= '' and host or Config:getDefault('Host'))
					end,
				},
				Input {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromScale(0, 1),
					Font = Theme.Fonts.Mono,
					PlaceholderText = '8000',
					Text = portInput,

					Changed = function(text)
						portInput:set(filterPort(text))
					end,

					Finished = function(port)
						props.App:setPort(port ~= '' and tonumber(port) or Config:getDefault('Port'))
					end,

					[Children] = {
						Text {
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.fromScale(0, 0.5),
							Text = ': ',
							Font = Theme.Fonts.Mono,
							Color = Theme.Colors.TextDimmed,
						},
					},
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
					Text = 'Connect',
					Activated = function()
						props.App:connect()
					end,
				},
				IconButton {
					Icon = Assets.Icons.Settings,
					LayoutOrder = 1,
					Activated = function()
						props.App:settings()
					end,
				},
				IconButton {
					Icon = Assets.Icons.Help,
					Activated = function()
						props.App:help()
					end,
				},
			},
		},
	}
end
