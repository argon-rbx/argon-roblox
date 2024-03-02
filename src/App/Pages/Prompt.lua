local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local TextButton = require(Components.TextButton)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local ForPairs = Fusion.ForPairs
local Children = Fusion.Children

return function(message: string, options: { string }, signal): { Instance }
	return {
		List {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		},
		Box {
			Size = UDim2.fromScale(1, 0),
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
		Container {
			Size = UDim2.fromScale(1, 0),
			[Children] = {
				List {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				ForPairs(options, function(_, index, option)
					return index,
						TextButton {
							LayoutOrder = #options - index + 1,
							Solid = index == 1,
							Text = option,
							Activated = function()
								signal:Fire(option)
							end,
						}
				end, Fusion.cleanup),
			},
		},
	}
end
