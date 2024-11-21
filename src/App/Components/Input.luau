local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local default = require(Util.default)
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
	"Started",
	"Changed",
	"Finished",
	"Font",
	"Color",
	"PlaceholderColor",
	"Scaled",
}

type Props = {
	Started: (() -> ())?,
	Changed: ((text: string) -> ())?,
	Finished: ((text: string) -> ())?,
	AutomaticSize: Enum.AutomaticSize?,
	Font: Fusion.CanBeState<Font>?,
	Color: Fusion.CanBeState<Color3>?,
	PlaceholderColor: Fusion.CanBeState<Color3>?,
	Scaled: boolean?,
	[any]: any,
}

return function(props: Props): TextBox
	local text = Value("")

	return Hydrate(New("TextBox") {
		AutomaticSize = default(props.AutomaticSize, Enum.AutomaticSize.None),
		FontFace = props.Font or Theme.Fonts.Regular,
		TextColor3 = props.Color or Theme.Colors.Text,
		PlaceholderColor3 = props.PlaceholderColor or Theme.Colors.TextDimmed,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextSize = Theme.TextSize.Large,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
		PlaceholderText = "...",
		TextScaled = props.Scaled,
		-- If the text is not scaled, enable ClipsDescendants so text scrolling works correctly.
		ClipsDescendants = not props.Scaled,

		[OnChange "Text"] = function(text)
			if props.Changed then
				props.Changed(text)
			end
		end,

		[OnEvent "Focused"] = function()
			if props.Started then
				props.Started()
			end
		end,

		[OnEvent "FocusLost"] = function()
			if props.Finished then
				props.Finished(peek(text))
			end
		end,

		[Out "Text"] = text,

		[Children] = props.Scaled and New("UITextSizeConstraint") {
			MaxTextSize = props.TextSize or Theme.TextSize.Large,
		} or nil,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
