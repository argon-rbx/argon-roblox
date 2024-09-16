local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local animate = require(Util.animate)
local stripProps = require(Util.stripProps)
local getState = require(Util.getState)
local isState = require(Util.isState)

local Corner = require(Components.Corner)
local List = require(Components.List)
local Box = require(Components.Box)

local New = Fusion.New
local Value = Fusion.Value
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Computed = Fusion.Computed
local Children = Fusion.Children
local ForValues = Fusion.ForValues
local peek = Fusion.peek

local BUTTON_COMPONENT_ONLY_PROPS = {
	"Activated",
	"IsSelected",
	"IsFirst",
	"IsLast",
}

type ButtonProps = {
	Activated: () -> (),
	IsSelected: Fusion.CanBeState<boolean>,
	IsFirst: boolean,
	IsLast: boolean,
	[any]: any,
}

local function Button(props: ButtonProps): TextButton
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

	return Hydrate(New "TextButton" {
		Size = UDim2.fromScale(1, 1),
		FontFace = Theme.Fonts.Regular,
		AutoButtonColor = false,
		TextSize = Theme.TextSize.Large,
		BackgroundColor3 = color,
		TextColor3 = Computed(function(use)
			return use(props.IsSelected) and use(Theme.Colors.TextBranded) or use(Theme.Colors.Text)
		end),

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
			if props.Activated then
				props.Activated()
			end
		end,

		[Children] = if props.IsFirst
			then {
				Corner {},
				New "Frame" {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromScale(0.1, 1),
					BackgroundColor3 = color,
					BorderSizePixel = 0,
				},
			}
			elseif props.IsLast then {
				Corner {},
				New "Frame" {
					Size = UDim2.fromScale(0.1, 1),
					BackgroundColor3 = color,
					BorderSizePixel = 0,
				},
			}
			else {},
	})(stripProps(props, BUTTON_COMPONENT_ONLY_PROPS))
end

local COMPONENT_ONLY_PROPS = {
	"Selected",
	"Options",
	"Value",
}

type Props = {
	Selected: ((option: string) -> ())?,
	Options: { string },
	Value: Fusion.CanBeState<boolean>?,
	[any]: any,
}

return function(props: Props): Frame
	local value = isState(props.Value) and props.Value or Value(props.Value or props.Options[1])

	return Hydrate(Box {
		Size = UDim2.new(1, 0, 0, Theme.CompSizeY.Small),
		AutomaticSize = Enum.AutomaticSize.None,

		[Children] = {
			List {
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalFlex = Enum.UIFlexAlignment.Fill,
				Spacing = 0,
			},
			ForValues(props.Options, function(_, option)
				return Button {
					Text = option,
					IsSelected = Computed(function(use)
						return use(value) == option
					end),

					Activated = function()
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
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
