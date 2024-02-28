local TextService = game:GetService('TextService')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local animate = require(Util.animate)
local stripProps = require(Util.stripProps)
local getState = require(Util.getState)

local List = require(Components.List)
local Box = require(Components.Box)

local New = Fusion.New
local Value = Fusion.Value
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Computed = Fusion.Computed
local Children = Fusion.Children
local ForValues = Fusion.ForValues
local peek = Fusion.peek

local BUTTON_COMPONENT_ONLY_PROPS = {
	'Activated',
	'Solid',
	'IsFirst',
	'IsLast',
}

type ButtonProps = {
	Activated: (() -> nil)?,
	Solid: Fusion.CanBeState<boolean>?,
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
			return use(props.Solid) and use(Theme.Colors.Brand) or use(Theme.Colors.Background)
		end),
		state
	)

	return Hydrate(New 'TextButton' {
		Text = 'Button',
		FontFace = Theme.Fonts.Regular,
		AutoButtonColor = false,
		TextSize = Theme.TextSize,

		Size = Computed(function(use)
			local text = use(props.Text)
			local size =
				TextService:GetTextSize(text, Theme.TextSize, Theme.Fonts.Enum, Vector2.new(math.huge, math.huge))

			return UDim2.fromOffset(size.X + 20, Theme.CompSizeY)
		end),

		BackgroundColor3 = color,
		TextColor3 = animate(Theme.Colors.Text, state),

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

		[Children] = if props.IsFirst
			then {
				New 'UICorner' {
					CornerRadius = Theme.CornerRadius,
				},
				New 'Frame' {
					AnchorPoint = Vector2.new(1, 0),
					-- temporary fix as scale with `UIFlexAlignment` combination is currently broken
					Position = Computed(function(use)
						return UDim2.fromOffset(use(absoluteSize).X + 1, 0)
					end),
					Size = UDim2.fromScale(0.1, 1),
					BackgroundColor3 = color,
					BorderSizePixel = 0,
				},
			}
			elseif props.IsLast then {
				New 'UICorner' {
					CornerRadius = Theme.CornerRadius,
				},
				New 'Frame' {
					Size = UDim2.fromScale(0.1, 1),
					BackgroundColor3 = color,
					BorderSizePixel = 0,
				},
			}
			else {},
	})(stripProps(props, BUTTON_COMPONENT_ONLY_PROPS))
end

local COMPONENT_ONLY_PROPS = {
	'Selected',
	'Options',
	'Initial',
}

type Props = {
	Selected: ((option: string) -> nil)?,
	Options: { string },
	Initial: string?,
	[any]: any,
}

return function(props: Props)
	local current = Value(props.Initial or props.Options[1])

	return Hydrate(Box {
		Size = UDim2.new(1, 0, 0, Theme.CompSizeY - 8),
		AutomaticSize = Enum.AutomaticSize.None,

		[Children] = {
			List {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Padding = 0,
			},
			ForValues(props.Options, function(_, option)
				return Button {
					Size = UDim2.fromScale(1, 1),
					Text = option,
					Solid = Computed(function(use)
						return use(current) == option
					end),

					Activated = function()
						if option == peek(current) then
							return
						end

						current:set(option)

						if props.Selected then
							props.Selected(option)
						end
					end,

					IsFirst = option == props.Options[1],
					IsLast = option == props.Options[#props.Options],
				}
			end, Fusion.cleanup),
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
