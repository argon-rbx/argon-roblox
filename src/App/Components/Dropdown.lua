local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local GlobalUtil = require(Argon.Util)

local Theme = require(App.Theme)
local Assets = require(App.Assets)
local animate = require(Util.animate)
local stripProps = require(Util.stripProps)
local getTextSize = require(Util.getTextSize)
local getState = require(Util.getState)
local isState = require(Util.isState)

local TextButton = require(Components.TextButton)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Image = require(Components.Image)
local List = require(Components.List)
local Box = require(Components.Box)

local New = Fusion.New
local Value = Fusion.Value
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Computed = Fusion.Computed
local Children = Fusion.Children
local ForValues = Fusion.ForValues
local peek = Fusion.peek

local BUTTON_COMPONENT_ONLY_PROPS = {
	'Activated',
	'IsSelected',
	'Transparency',
	'IsFirst',
	'IsLast',
}

type ButtonProps = {
	Activated: () -> (),
	IsSelected: Fusion.Computed<boolean>,
	Transparency: Fusion.Spring<number>,
	IsFirst: boolean,
	IsLast: boolean,
	[any]: any,
}

local function Button(props: ButtonProps): TextButton
	local absoluteSize = Value(Vector2.new())
	local isHovered = Value(false)
	local isPressed = Value(false)

	local state = getState({
		Hovered = isHovered,
		Pressed = isPressed,
	})

	local color = animate(
		Computed(function(use)
			return use(props.IsSelected) and use(Theme.Colors.Brand) or use(Theme.Colors.Background)
		end),
		state
	)

	return Hydrate(New 'TextButton' {
		Text = 'Button',
		Size = UDim2.fromScale(1, 1),
		FontFace = Theme.Fonts.Regular,
		AutoButtonColor = false,
		TextSize = Theme.TextSize,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = color,
		TextColor3 = animate(Theme.Colors.Text, state),
		TextTransparency = props.Transparency,
		BackgroundTransparency = props.Transparency,

		[OnEvent 'InputBegan'] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(true)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				isPressed:set(true)
			end
		end,
		[OnEvent 'InputEnded'] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(false)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				isPressed:set(false)
			end
		end,
		[OnEvent('Activated')] = function()
			if props.Activated then
				props.Activated()
			end
		end,

		[OnChange 'AbsoluteSize'] = function(size)
			absoluteSize:set(size)
		end,

		[Children] = GlobalUtil.join(
			{
				Padding {
					Padding = 6,
					Vertical = false,
				},
			},
			if props.IsFirst
				then {
					New 'UICorner' {
						CornerRadius = Theme.CornerRadius,
					},
					New 'Frame' {
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.fromScale(0.5, 1),
						Size = UDim2.fromScale(1.2, 0.2),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
					},
				}
				elseif props.IsLast then {
					New 'UICorner' {
						CornerRadius = Theme.CornerRadius,
					},
					New 'Frame' {
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 0),
						Size = UDim2.fromScale(1.2, 0.2),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
					},
				}
				else {}
		),
	})(stripProps(props, BUTTON_COMPONENT_ONLY_PROPS))
end

local COMPONENT_ONLY_PROPS = {
	'Selected',
	'Options',
	'Value',
}

type Props = {
	Selected: ((option: string) -> ())?,
	Options: { string },
	Value: Fusion.CanBeState<boolean>?,
	[any]: any,
}

return function(props: Props)
	local value = isState(props.Value) and props.Value or Value(props.Value or props.Options[1])
	local isOpen = Value(false)

	local anchorPoint = Vector2.zero

	local size
	do
		local maxSize = Vector2.zero

		for _, option in ipairs(props.Options) do
			local textSize = getTextSize(option)

			if textSize.X > maxSize.X then
				maxSize = textSize
			end
		end

		size = UDim2.fromOffset(maxSize.X + 50, Theme.CompSizeY - 6)
	end

	local transparency = Spring(
		Computed(function(use)
			return use(isOpen) and 0 or 1
		end),
		30
	)

	return Hydrate(TextButton {
		TextXAlignment = Enum.TextXAlignment.Left,
		Size = size,
		Text = value,

		Activated = function()
			isOpen:set(not peek(isOpen))
		end,

		[Children] = {
			Padding {
				Padding = 6,
				Vertical = false,
			},
			Image {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(16, 16),
				Image = Assets.Icons.Dropdown,
			},
			Container {
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0),
				Size = UDim2.new(1, 12, 1, 0),
				AutomaticSize = Enum.AutomaticSize.None,

				[Children] = {
					Box {
						ZIndex = 5,
						ClipsDescendants = true,
						AutomaticSize = Enum.AutomaticSize.None,
						BorderTransparency = transparency,
						BackgroundTransparency = transparency,

						AnchorPoint = Computed(function(use)
							if use(isOpen) then
								local index = table.find(props.Options, peek(value))
								anchorPoint = Vector2.new(0, (index - 1) / #props.Options)
							end

							return anchorPoint
						end),

						Size = Spring(
							Computed(function(use)
								return UDim2.fromScale(1, use(isOpen) and #props.Options or 0)
							end),
							50
						),

						[Children] = {
							List {
								VerticalFlex = Enum.UIFlexAlignment.Fill,
								Padding = 0,
							},
							ForValues(props.Options, function(_, option)
								return Button {
									Text = option,
									Transparency = transparency,

									IsSelected = Computed(function(use)
										return use(value) == option
									end),

									Activated = function()
										isOpen:set(false)

										if option == peek(value) then
											return
										end

										value:set(option)

										if props.Selected then
											props.Selected(option)
										end
									end,

									IsFirst = option == props.Options[1],
									IsLast = option == props.Options[#props.Options],
								}
							end, Fusion.cleanup),
						},
					},
				},
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
