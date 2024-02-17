local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local Components = script.Parent
local Util = Components.Util

local Enums = require(Util.Enums)
local Types = require(Util.Types)
local Defaults = require(Util.Defaults)
local stripProps = require(Util.stripProps)
local mapColor = require(Util.mapColor)

local New = Fusion.New
local Hydrate = Fusion.Hydrate
local Computed = Fusion.Computed
local peek = Fusion.peek

local COMPONENT_ONLY_PROPS = {
	'Font',
	'Color',
}

type Props = {
	Text: Types.CanBeState<string>,
	Font: Types.CanBeState<Enums.Font>?,
	Color: Types.CanBeState<Enums.Color | Color3>?,
	[any]: any,
}

return function(props: Props): TextLabel
	local font = Computed(function()
		local font = peek(props.Font)

		if font then
			return Defaults.Fonts[Enums:GetName(Enums.Font, font)]
		else
			return Defaults.Fonts.Default
		end
	end)

	return Hydrate(New('TextLabel') {
		FontFace = font,
		TextColor3 = mapColor(props.Color, Enums.Color.Text),
		TextSize = props.TextSize or Defaults.TextSize,
		AutomaticSize = Enum.AutomaticSize.XY,
		BorderSizePixel = 0,
		BackgroundTransparency = 1,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
