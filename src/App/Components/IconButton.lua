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
local Image = require(Components.Image)

local New = Fusion.New
local Value = Fusion.Value
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
	'Activated',
	'Solid',
	'Icon',
}

type Props = {
	Activated: (() -> nil)?,
	Solid: Fusion.CanBeState<boolean>?,
	Icon: Fusion.CanBeState<string>?,
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
		Size = UDim2.fromOffset(Theme.CompSizeY, Theme.CompSizeY),
		Text = '',
		AutoButtonColor = false,
		BackgroundColor3 = color,

		[OnEvent 'InputBegan'] = function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(true)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
				isPressed:set(true)
			end
		end,
		[OnEvent 'InputEnded'] = function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(false)
			elseif inputObject.UserInputType == Enum.UserInputType.MouseButton1 then
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
			Image {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.6, 0.6),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ImageColor3 = animateState(Theme.Colors.Text, state),
				Image = props.Icon,
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
