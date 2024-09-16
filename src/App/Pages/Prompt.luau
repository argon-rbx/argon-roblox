local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)
local Signal = require(Argon.Packages.Signal)

local Theme = require(App.Theme)
local getTextSize = require(Util.getTextSize)

local ScrollingContainer = require(Components.ScrollingContainer)
local TextButton = require(Components.TextButton)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Value = Fusion.Value
local Computed = Fusion.Computed
local ForPairs = Fusion.ForPairs
local OnChange = Fusion.OnChange
local Children = Fusion.Children

type Props = {
	App: { [string]: any },
	Message: string,
	Options: { string },
	Signal: Signal.Signal,
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
		Container {
			Size = UDim2.fromScale(1, 0),
			[Children] = {
				List {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				ForPairs(props.Options, function(_, index, option)
					return index,
						TextButton {
							LayoutOrder = #props.Options - index + 1,
							Solid = index == 1,
							Text = option,
							Activated = function()
								props.Signal:Fire(option)
							end,
						}
				end, Fusion.cleanup),
			},
		},
	}
end
