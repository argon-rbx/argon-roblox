local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local Components = script.Parent
local Util = Components.Util

local Enums = require(Util.Enums)
local Defaults = require(Util.Defaults)
local ThemeProvider = require(Util.ThemeProvider)
local stripProps = require(Util.stripProps)
local getState = require(Util.getState)

local Border = require(Components.Border)

local New = Fusion.New
local Value = Fusion.Value
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Children = Fusion.Children

local COMPONENT_ONLY_PROPS = {
	'Activated',
}

type Props = {
	Activated: (() -> nil)?,
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
		Text = 'Button',
		Size = UDim2.fromOffset(120, 40),
		FontFace = props.Font or Defaults.Fonts.Default,
		AutoButtonColor = false,
		TextSize = Defaults.TextSize,
		BackgroundColor3 = Spring(ThemeProvider:GetColor(Enums.Color.Primary, state), 30),
		TextColor3 = Spring(ThemeProvider:GetColor(Enums.Color.Text, state), 30),

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
			Border {},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
