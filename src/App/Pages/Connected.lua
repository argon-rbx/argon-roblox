local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Assets = require(App.Assets)
local Theme = require(App.Theme)

local TextButton = require(Components.TextButton)
local IconButton = require(Components.IconButton)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Children = Fusion.Children

return function(app, details: { [string]: any }): { Instance }
	return {
		List {},
		Box {
			Size = UDim2.new(1, 0, 0, Theme.CompSizeY * 1.5),
			[Children] = {
				Padding {},
				Text {
					Size = UDim2.fromScale(0.75, 0.6),
					Text = details.name,
					Font = Theme.Fonts.Bold,
					Scaled = true,
				},
				Text {
					Position = UDim2.fromScale(0, 0.6),
					Size = UDim2.fromScale(0.75, 0.4),
					Text = `{app.client.host}:{app.client.port}`,
					TextSize = Theme.TextSize - 4,
					Font = Theme.Fonts.Mono,
					Scaled = true,
				},
				IconButton {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.fromScale(1, 0.5),
					Icon = Assets.Icons.Info,
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
					Text = 'Disconnect',
					LayoutOrder = 2,
					Solid = true,

					Activated = function()
						app:disconnect()
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
