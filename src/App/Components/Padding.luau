local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)
local stripProps = require(Util.stripProps)

local New = Fusion.New
local Hydrate = Fusion.Hydrate

local COMPONENT_ONLY_PROPS = {
	"Padding",
	"Horizontal",
	"Vertical",
	"Left",
	"Right",
	"Top",
	"Bottom",
}

type Props = {
	-- Mode 1
	Padding: number?,
	-- Mode 2
	Horizontal: number?,
	Vertical: number?,
	-- Mode 3
	Left: number?,
	Right: number?,
	Top: number?,
	Bottom: number?,
	[any]: any,
}

return function(props: Props): UIPadding
	local left, right
	local top, bottom

	if props.Left or props.Right or props.Top or props.Bottom then
		local padding = props.Padding or 0

		left = UDim.new(0, props.Left or padding)
		right = UDim.new(0, props.Right or padding)
		top = UDim.new(0, props.Top or padding)
		bottom = UDim.new(0, props.Bottom or padding)
	elseif props.Horizontal or props.Vertical then
		local padding = props.Padding or 0
		local horizontal = UDim.new(0, props.Horizontal or padding)
		local vertical = UDim.new(0, props.Vertical or padding)

		left = horizontal
		right = horizontal
		top = vertical
		bottom = vertical
	else
		local padding = UDim.new(0, props.Padding or Theme.Padding)

		left = padding
		right = padding
		top = padding
		bottom = padding
	end

	return Hydrate(New "UIPadding" {
		PaddingLeft = left,
		PaddingRight = right,
		PaddingTop = top,
		PaddingBottom = bottom,
	})(stripProps(props, COMPONENT_ONLY_PROPS))
end
