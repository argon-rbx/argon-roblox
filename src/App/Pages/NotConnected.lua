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
	App: { [any]: any },
}

local function getConfigValue(key: string): string
	local config = Config:get(key)
	local default = Config:getDefault(key)

	if config == nil or config == default then
		return ''
	else
		return config
	end
end

return function(props: Props): { Instance }
	local hostInput = Value(getConfigValue('host'))
	local portInput = Value(getConfigValue('port'))

	return {
		List {},
		Box {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
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
						props.App.client:setHost(host ~= '' and host or Config:getDefault('host'))
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
						props.App.client:setPort(port ~= '' and tonumber(port) or Config:getDefault('port'))
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
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 0),
			[Children] = {
				List {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				TextButton {
					Solid = true,
					LayoutOrder = 1,
					Text = 'Connect',
					Size = UDim2.fromOffset(96, Theme.CompSizeY),
					Activated = function()
						props.App.client:subscribe():andThen(function(test)
							print(test)
						end)
					end,
				},
				IconButton {
					Icon = Assets.Icons.Settings,
					Activated = function()
						props.App:openSettings()
					end,
				},
			},
		},
	}
end
