local Argon = script:FindFirstAncestor('Argon')
local App = script:FindFirstAncestor('App')
local Components = script.Parent
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Enums = require(App.Enums)
local Style = require(App.Style)
local Types = require(App.Types)
local ThemeProvider = require(App.ThemeProvider)
local stripProps = require(Util.stripProps)
local getState = require(Util.getState)

local Border = require(Components.Border)
local Image = require(Components.Image)

local New = Fusion.New
local Value = Fusion.Value
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
	'Activated',
	'Icon',
}

type Props = {
	Activated: (() -> nil)?,
	Icon: Types.CanBeState<string>?,
	[any]: any,
}

return function(props: Props): TextButton
	local isHovered = Value(false)
	local isPressed = Value(false)

	local state = getState({
		Hovered = isHovered,
		Pressed = isPressed,
	})

	return Hydrate(New 'TextButton' {
		Name = 'BaseButton',
		Size = UDim2.fromOffset(Style.CompSizeY, Style.CompSizeY),
		Text = '',
		AutoButtonColor = false,
		BackgroundColor3 = Spring(ThemeProvider:GetColor(Enums.Color.Background, state), 30),

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
			Border {},
			Image {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.65, 0.65),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ImageColor3 = Spring(ThemeProvider:GetColor(Enums.Color.Text, state), 30),
				Image = props.Icon,
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
