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

local function loadConfigValue(setting: Config.Setting): string
	local config = Config:get(setting)
	local default = Config:getDefault(setting)

	if config == nil or config == default then
		return ''
	else
		return config
	end
end

return function(app): { Instance }
	local hostInput = Value(loadConfigValue('Host'))
	local portInput = Value(loadConfigValue('Port'))

	return {
		List {},
		Box {
			Size = UDim2.new(1, 0, 0, Theme.CompSizeY),
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
						app:setHost(host ~= '' and host or Config:getDefault('Host'))
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
						app:setPort(port ~= '' and tonumber(port) or Config:getDefault('Port'))
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
						app:connect()
					end,
				},
				IconButton {
					Icon = Assets.Icons.Settings,
					LayoutOrder = 1,
					Activated = function()
						app:settings()
					end,
				},
				IconButton {
					Icon = Assets.Icons.Help,
					Activated = function()
						app:help()
					end,
				},
			},
		},
	}
end
