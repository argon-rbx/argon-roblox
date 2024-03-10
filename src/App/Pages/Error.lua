local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local TextButton = require(Components.TextButton)
local ScrollingContainer = require(Components.ScrollingContainer)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Children = Fusion.Children

return function(app, message: string): { Instance }
	return {
		List {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		},

		Box {
			Size = UDim2.fromScale(1, 0.55),
			[Children] = {
				ScrollingContainer {
					[Children] = {
						Padding {},
						Text {
							Text = message,
							TextWrapped = true,
							Font = Theme.Fonts.Mono,
							TextSize = Theme.TextSize - 2,
						},
					},
				},
			},
		},
		TextButton {
			Text = 'Proceed',
			Activated = function()
				app:home()
			end,
		},
	}
end
