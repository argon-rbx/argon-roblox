local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local Assets = require(App.Assets)
local animate = require(Util.animate)
local getState = require(Util.getState)
local stripProps = require(Util.stripProps)

local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Corner = require(Components.Corner)
local Image = require(Components.Image)
local List = require(Components.List)
local Text = require(Components.Text)
local Box = require(Components.Box)

local New = Fusion.New
local Value = Fusion.Value
local Tween = Fusion.Tween
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local peek = Fusion.peek

local COMPONENT_ONLY_PROPS = {
	"Title",
	"Expanded",
	"Elements",
}

type Props = {
	Title: string,
	Expanded: boolean?,
	Elements: { Instance },
}

return function(props: Props): Frame
	local isExpanded = Value(props.Expanded or false)
	local absoluteSize = Value(Vector2.zero)

	local isHovered = Value(false)
	local isPressed = Value(false)

	local state = getState({
		Hovered = isHovered,
		Pressed = isPressed,
	})

	local color = animate(
		Computed(function(use)
			return use(Theme.Colors.Background)
		end),
		state
	)

	return Hydrate(Box {
		ClipsDescendants = true,
		AutomaticSize = Enum.AutomaticSize.None,
		Size = Spring(
			Computed(function(use)
				return UDim2.new(1, 0, 0, Theme.CompSizeY.Large + (use(isExpanded) and use(absoluteSize).Y or 0))
			end),
			30
		),

		[Children] = {
			New "TextButton" {
				Text = "",
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 0, Theme.CompSizeY.Large),
				BackgroundColor3 = color,

				[OnEvent "InputBegan"] = function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement then
						isHovered:set(true)
					elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
						isPressed:set(true)
					end
				end,
				[OnEvent "InputEnded"] = function(input)
					if input.UserInputType == Enum.UserInputType.MouseMovement then
						isHovered:set(false)
					elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
						isPressed:set(false)
					end
				end,
				[OnEvent("Activated")] = function()
					isExpanded:set(not peek(isExpanded))
				end,

				[Children] = {
					Corner {},
					Container {
						Size = UDim2.fromScale(1, 1),
						[Children] = {
							Padding {},
							Text {
								Text = props.Title,
								FontFace = Theme.Fonts.Bold,
								TextSize = Theme.TextSize.Large,
								TextXAlignment = Enum.TextXAlignment.Left,
								Size = UDim2.fromScale(1, 1),
								Color = Computed(function(use)
									return use(Theme.Colors.Text)
								end),
							},
							Image {
								AnchorPoint = Vector2.new(1, 0.5),
								Position = UDim2.fromScale(1, 0.5),
								Size = UDim2.fromOffset(16, 16),
								Image = Assets.Icons.Expand,
								Rotation = Spring(
									Computed(function(use)
										return use(isExpanded) and 180 or 0
									end),
									30
								),
							},
						},
					},
					New "Frame" {
						AnchorPoint = Vector2.new(0, 1),
						Position = UDim2.fromScale(0, 1),
						Size = UDim2.fromScale(1, 0.2),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
						BackgroundTransparency = Tween(
							Computed(function(use)
								return use(isExpanded) and 0 or 1
							end),
							TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
						),
					},
				},
			},
			Container {
				Size = UDim2.fromScale(1, 0),
				Position = UDim2.fromOffset(0, Theme.CompSizeY.Large),
				[OnChange "AbsoluteSize"] = function(size)
					absoluteSize:set(size)
				end,
				[Children] = {
					List {
						Spacing = 0,
					},
					props.Elements,
				},
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
