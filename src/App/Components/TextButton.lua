local TextService = game:GetService('TextService')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local animateState = require(Util.animateState)
local stripProps = require(Util.stripProps)
local getState = require(Util.getState)

local Border = require(Components.Border)

local New = Fusion.New
local Value = Fusion.Value
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
	'Activated',
	'Solid',
}

type Props = {
	Activated: (() -> nil)?,
	Solid: Fusion.CanBeState<boolean>?,
	[any]: any,
}

return function(props: Props): TextButton
	local isHovered = Value(false)
	local isPressed = Value(false)

	local state = getState({
		Hovered = isHovered,
		Pressed = isPressed,
	})

	local color = animateState(
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
		TextColor3 = animateState(Theme.Colors.Text, state),

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

		[Children] = {
			Border {
				Color = Computed(function(use)
					return use(props.Solid) and use(color) or use(Theme.Colors.Border)
				end),
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
