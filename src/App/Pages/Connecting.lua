local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local TextButton = require(Components.TextButton)
local Spinner = require(Components.Spinner)
local List = require(Components.List)
local Box = require(Components.Box)

local Value = Fusion.Value

local Children = Fusion.Children

return function(app): { Instance }
	local visible = Value(false)

	-- this prevents flickering in case the loading is too fast
	-- (most of the time as users usually connect to local server)
	task.spawn(function()
		wait(0.1)
		visible:set(true)
	end)

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
					Visible = visible,
				},
			},
		},
		TextButton {
			Text = 'Cancel',
			Activated = function()
				app:home()
			end,
		},
	}
end
