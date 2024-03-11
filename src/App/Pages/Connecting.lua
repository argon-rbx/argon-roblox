local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local TextButton = require(Components.TextButton)
local Spinner = require(Components.Spinner)
local List = require(Components.List)
local Box = require(Components.Box)

local Children = Fusion.Children

type Props = {
	App: { [string]: any },
}

return function(props: Props): { Instance }
	return {
		List {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		},
		Box {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(1, 0, 0, Theme.CompSizeY * 1.5),
			[Children] = {
				Spinner {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
				},
			},
		},
		TextButton {
			Text = 'Cancel',
			Activated = function()
				props.App:disconnect()
				props.App:home()
			end,
		},
	}
end
