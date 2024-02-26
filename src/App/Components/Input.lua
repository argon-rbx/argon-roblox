local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local Types = require(App.Types)
local stripProps = require(Util.stripProps)

local New = Fusion.New
local Out = Fusion.Out
local Value = Fusion.Value
local Hydrate = Fusion.Hydrate
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Children = Fusion.Children
local peek = Fusion.peek

local COMPONENT_ONLY_PROPS = {
	'Changed',
	'Finished',
	'Font',
	'Color',
	'PlaceholderColor',
	'Scaled',
}

type Props = {
	Changed: ((text: string) -> nil)?,
	Finished: ((text: string) -> nil)?,
	Font: Types.CanBeState<Font>?,
	Color: Types.CanBeState<Color3>?,
	PlaceholderColor: Types.CanBeState<Color3>?,
	Scaled: boolean?,
	[any]: any,
}

return function(props: Props): TextBox
	local text = Value('')

	return Hydrate(New('TextBox') {
		FontFace = props.Font or Theme.Fonts.Regular,
		TextColor3 = props.Color or Theme.Colors.Text,
		PlaceholderColor3 = props.PlaceholderColor or Theme.Colors.TextDimmed,
		TextXAlignment = Enum.TextXAlignment.Left,
		AutomaticSize = props.Scaled and Enum.AutomaticSize.None or Enum.AutomaticSize.XY,
		TextSize = Theme.TextSize,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		TextScaled = props.Scaled,
		PlaceholderText = '...',

		[OnChange 'Text'] = function(text)
			if props.Changed then
				props.Changed(text)
			end
		end,

		[OnEvent 'FocusLost'] = function()
			if props.Finished then
				props.Finished(peek(text))
			end
		end,

		[Out 'Text'] = text,

		[Children] = props.Scaled and New('UITextSizeConstraint') {
			MaxTextSize = Theme.TextSize,
		} or nil,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
