local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local getTextSize = require(Util.getTextSize)

local TextButton = require(Components.TextButton)
local ScrollingContainer = require(Components.ScrollingContainer)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Value = Fusion.Value
local Computed = Fusion.Computed
local OnChange = Fusion.OnChange
local Children = Fusion.Children

type Props = {
	App: { [string]: any },
	Message: string,
}

return function(props: Props): { Instance }
	local absoluteSize = Value(Vector2.zero)

	return {
		List {
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
		},
		Box {
			AutomaticSize = Enum.AutomaticSize.None,
			Size = Computed(function(use)
				local absoluteSize = use(absoluteSize)
				local rootSize = use(props.App.rootSize)

				local size = getTextSize(
					props.Message,
					Theme.TextSize.Medium,
					Theme.Fonts.Enums.Mono,
					Vector2.new(absoluteSize.X - Theme.Padding * 2 - 2, math.huge)
				)
				local height = math.min(size.Y + Theme.Padding * 2, rootSize.Y - 120)

				return UDim2.new(1, 0, 0, height)
			end),

			[OnChange "AbsoluteSize"] = function(size)
				absoluteSize:set(size)
			end,

			[Children] = {
				ScrollingContainer {
					Size = UDim2.new(1, -2, 1, 0),
					ScrollBar = true,
					[Children] = {
						Padding {},
						Text {
							Text = props.Message,
							RichText = true,
							TextWrapped = true,
							Font = Theme.Fonts.Mono,
							TextSize = Theme.TextSize.Medium,
						},
					},
				},
			},
		},
		TextButton {
			Text = "Proceed",
			Activated = function()
				props.App:home()
			end,
		},
	}
end
