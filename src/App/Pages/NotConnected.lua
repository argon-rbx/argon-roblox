local Components = script.Parent.Parent.Components

local Assets = require(script.Parent.Parent.Assets)

local TextButton = require(Components.TextButton)
local IconButton = require(Components.IconButton)

type Props = {
	[any]: any,
}

return function(_props: Props): { Instance }
	return {
		TextButton {
			Position = UDim2.fromScale(0.08, 0.1),
			Text = 'Click Me!',
			Activated = function()
				print('Button clicked!')
			end,
		},

		IconButton {
			Position = UDim2.fromScale(0.5, 0.5),
			Icon = Assets.Icons.Settings,
		},
	}
end
