local TextService = game:GetService('TextService')

local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local App = script:FindFirstAncestor('App')
local Components = script.Parent
local Util = Components.Util

local Enums = require(App.Enums)
local Style = require(App.Style)
local ThemeProvider = require(Util.ThemeProvider)
local stripProps = require(Util.stripProps)
local getState = require(Util.getState)

local Border = require(Components.Border)

local New = Fusion.New
local Value = Fusion.Value
local Spring = Fusion.Spring
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
	Solid: boolean?,
	[any]: any,
}

return function(props: Props): TextButton
	local isHovered = Value(false)
	local isPressed = Value(false)

	local state = getState({
		Hovered = isHovered,
		Pressed = isPressed,
	})

	props.Text = props.Text or 'Button'
	props.Size = props.Size
		or Computed(function(use)
			local text = use(props.Text)
			local size =
				TextService:GetTextSize(text, Style.TextSize, Enum.Font.Ubuntu, Vector2.new(math.huge, math.huge))

			return UDim2.fromOffset(size.X + 20, Style.YSize)
		end)

	return Hydrate(New 'TextButton' {
		FontFace = Style.Fonts.Default,
		AutoButtonColor = false,
		TextSize = Style.TextSize,
		BackgroundColor3 = Spring(
			ThemeProvider:GetColor(props.Solid and Enums.Color.Brand or Enums.Color.Background, state),
			30
		),
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
			Border {
				Color = props.Solid and Spring(
					ThemeProvider:GetColor(props.Solid and Enums.Color.Brand or Enums.Color.Background, state),
					30
				) or nil,
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
