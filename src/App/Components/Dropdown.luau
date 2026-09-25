local Argon = script:FindFirstAncestor("Argon")
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

local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Corner = require(Components.Corner)
local Image = require(Components.Image)
local Input = require(Components.Input)
local List = require(Components.List)
local Box = require(Components.Box)

local New = Fusion.New
local Ref = Fusion.Ref
local Value = Fusion.Value
local Spring = Fusion.Spring
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local Cleanup = Fusion.Cleanup
local Computed = Fusion.Computed
local Children = Fusion.Children
local Observer = Fusion.Observer
local ForValues = Fusion.ForValues
local cleanup = Fusion.cleanup
local peek = Fusion.peek

local BUTTON_COMPONENT_ONLY_PROPS = {
	"Activated",
	"Pressed",
	"Released",
	"IsSelected",
	"IsDimmed",
	"IsFirst",
	"IsLast",
}

type ButtonProps = {
	Activated: () -> (),
	Pressed: (() -> ())?,
	Released: (() -> ())?,
	IsSelected: Fusion.Computed<boolean>,
	IsDimmed: Fusion.Computed<boolean>,
	IsFirst: Fusion.Value<boolean>?,
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
	local lastState = peek(state)

	local color = animate(
		Computed(function(use)
			return use(props.IsSelected) and use(Theme.Colors.Brand) or use(Theme.Colors.Background)
		end),
		state
	)

	-- Hide very minor hover flicker of the first button when the dropdown is expanded
	local disconnect = Observer(state):onChange(function()
		if props.IsFirst and not peek(props.IsFirst) then
			local state = peek(state)

			if state == Enum.GuiState.Idle and lastState == Enum.GuiState.Press then
				task.defer(function()
					if peek(props.IsFirst) then
						color:setPosition(
							peek(props.IsSelected) and peek(Theme.Colors.Brand) or peek(Theme.Colors.Background)
						)
					end
				end)
			end

			lastState = state
		end
	end)

	return Hydrate(New "TextButton" {
		Size = UDim2.new(1, 0, 0, Theme.CompSizeY.Medium),
		FontFace = Theme.Fonts.Regular,
		AutoButtonColor = false,
		TextSize = Theme.TextSize.Large,
		TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundColor3 = color,
		TextColor3 = Computed(function(use)
			return use(props.IsSelected) and use(Theme.Colors.TextBranded)
				or use(props.IsDimmed) and use(Theme.Colors.TextDimmed)
				or use(Theme.Colors.Text)
		end),
		[OnEvent "InputBegan"] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(true)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				isPressed:set(true)
				if props.Pressed then
					props.Pressed()
				end
			end
		end,
		[OnEvent "InputEnded"] = function(input)
			if input.UserInputType == Enum.UserInputType.MouseMovement then
				isHovered:set(false)
			elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
				isPressed:set(false)
				if props.Released then
					props.Released()
				end
			end
		end,
		[OnEvent "Activated"] = function()
			if props.IsFirst then
				isHovered:set(false)
				isPressed:set(false)
			end

			props.Activated()
		end,
		[Cleanup] = disconnect,
		[Children] = GlobalUtil.join(
			{
				Padding {
					Horizontal = 6,
				},
			},
			if props.IsFirst
				then {
					Corner {},
					New "Frame" {
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.fromScale(0.5, 1),
						Size = UDim2.fromScale(1.2, 0.2),
						BackgroundColor3 = color,
						BorderSizePixel = 0,
						Visible = Computed(function(use)
							return use(props.IsFirst)
						end),
					},
				}
				elseif props.IsLast then {
					Corner {},
					New "Frame" {
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
	"Selected",
	"Options",
	"Value",
	"Placeholder",
}

type Props = {
	Selected: ((option: string) -> ())?,
	Options: { string },
	Value: Fusion.CanBeState<string>?,
	Placeholder: Fusion.CanBeState<string>?,
	[any]: any,
}

return function(props: Props): TextButton
	local value = isState(props.Value) and props.Value or Value(props.Value or props.Options[1])
	local placeholder = isState(props.Placeholder) and props.Placeholder or Value(props.Placeholder or props.Options[1])

	local isOpen = Value(false)
	local anchor = Value(0)
	local ref = Value(nil)
	local isPressingOption = false
	local wasOpenWhenPressed = false

	local size
	do
		local maxSize = Vector2.zero

		for _, option in props.Options do
			local textSize = getTextSize(option)

			if textSize.X > maxSize.X then
				maxSize = textSize
			end
		end

		size = UDim2.fromOffset(maxSize.X + 40, Theme.CompSizeY.Medium)
	end

	return Hydrate(Container {
		AutomaticSize = Enum.AutomaticSize.None,
		Size = size,
		[Children] = {
			Padding {
				Horizontal = 6,
			},
			Image {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(16, 16),
				Image = Assets.Icons.Dropdown,
				ImageColor3 = Theme.Colors.Text,
				ZIndex = 2,
				ImageTransparency = Computed(function(use)
					return use(isOpen) and 1 or 0
				end),
			},
			Input {
				Finished = function()
					task.defer(function()
						if not isPressingOption then
							isOpen:set(false)
						end
					end)
				end,
				[Ref] = ref,
			},
			Box {
				ClipsDescendants = true,
				AutomaticSize = Enum.AutomaticSize.None,
				Size = Spring(
					Computed(function(use)
						return UDim2.new(1, 12, use(isOpen) and #props.Options or 1, 0)
					end),
					40
				),
				AnchorPoint = Computed(function(use)
					if use(isOpen) then
						local index = table.find(props.Options, peek(value))
						anchor:set((index - 1) / #props.Options)
					end

					return Vector2.new(0.5, peek(anchor))
				end),
				Position = Computed(function(use)
					return UDim2.fromScale(0.5, use(isOpen) and 0 or use(anchor))
				end),
				[Children] = {
					Container {
						Size = UDim2.fromScale(1, #props.Options),
						[Children] = {
							List {
								Spacing = 0,
							},
							ForValues(props.Options, function(_, option)
								local isFirst = option == props.Options[1]

								return Button {
									Text = Computed(function(use)
										if isFirst then
											return use(isOpen) and option or use(value)
										else
											return option
										end
									end),
									IsSelected = Computed(function(use)
										return use(isOpen) and use(value) == option
									end),
									IsDimmed = Computed(function(use)
										return not use(isOpen) and use(value) ~= use(placeholder)
									end),
									Pressed = function()
										wasOpenWhenPressed = peek(isOpen)
										isPressingOption = true
									end,
									Released = function()
										isPressingOption = false
										task.defer(function()
											if wasOpenWhenPressed then
												wasOpenWhenPressed = false
												isOpen:set(false)
											end
										end)
									end,
									Activated = function()
										local wasOpen = wasOpenWhenPressed
										wasOpenWhenPressed = false
										isPressingOption = false

										if not wasOpen then
											isOpen:set(true)
											peek(ref):CaptureFocus()
											return
										end

										isOpen:set(false)

										if option == peek(value) then
											return
										end

										value:set(option)

										if props.Selected then
											props.Selected(option)
										end
									end,
									IsFirst = isFirst and isOpen or nil,
									IsLast = option == props.Options[#props.Options],
								}
							end, cleanup),
						},
					},
				},
			},
		},
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
