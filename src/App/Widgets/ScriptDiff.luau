local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)
local Highlighter = require(Argon.Packages.Highlighter)
local Differ = require(Argon.Lib.Differ)

local GlobalUtil = require(Argon.Util)
local Config = require(Argon.Config)
local Theme = require(App.Theme)
local getTextSize = require(Util.getTextSize)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local List = require(Components.List)
local Text = require(Components.Text)

local Children = Fusion.Children
local ForPairs = Fusion.ForPairs
local cleanup = Fusion.cleanup

type Props = {
	Name: string,
	OldSource: string,
	NewSource: string?,
	Closed: (() -> ())?,
}

Highlighter.matchStudioSettings()

return function(props: Props): DockWidgetPluginGui
	local source = props.OldSource
	local colors = {}

	if props.NewSource then
		source = Differ.diff(props.OldSource, props.NewSource)
	end

	do
		local lineLimit = Config:get("DiffLinesLimit")
		local lines = source:split("\n")
		local total = #lines
		local new = {}

		for i = 1, math.min(total, lineLimit) do
			new[i] = lines[i]
			colors[i] = lines[i]:find("^%+") and Theme.Colors.Diff.Add
				or lines[i]:find("^%-") and Theme.Colors.Diff.Remove
				or nil
		end

		local remaining = total - lineLimit

		if total > lineLimit then
			table.insert(new, `-- And {remaining} more line{GlobalUtil.plural(remaining)}...`)
		end

		source = table.concat(new, "\n")
	end

	local highlighted = Highlighter.buildRichTextLines({
		src = source,
	})

	local lineWidth = getTextSize(
		tostring(#highlighted),
		Theme.TextSize.Medium,
		Theme.Fonts.Enums.MonoBold,
		Vector2.new(math.huge, Theme.TextSize.Medium)
	).X + Theme.Padding

	return Widget {
		Name = `Argon - Script Diff ({props.Name})`,
		OverrideEnabled = true,
		MinimumSize = Vector2.new(700, 500),
		Closed = props.Closed,
		[Children] = {
			Padding {
				Right = 4,
			},
			ScrollingContainer {
				ScrollBar = true,
				[Children] = {
					List {
						Spacing = 0,
					},
					Padding {
						Vertical = Theme.Padding / 2,
					},
					ForPairs(highlighted, function(_, index, line)
						local color = colors[index]

						return index,
							Container {
								Size = UDim2.fromScale(1, 0),
								BackgroundColor3 = color,
								BackgroundTransparency = color and 0.9 or 1,
								LayoutOrder = index,
								[Children] = {
									Text {
										Size = UDim2.new(0, lineWidth, 1, 0),
										Font = Theme.Fonts.MonoBold,
										TextXAlignment = Enum.TextXAlignment.Right,
										TextSize = Theme.TextSize.Medium,
										Text = index,
									},
									Text {
										Position = UDim2.fromOffset(lineWidth + Theme.Padding * 2, 0),
										Size = UDim2.new(1, -lineWidth - Theme.Padding * 2, 1, 0),
										Font = Theme.Fonts.Mono,
										TextSize = Theme.TextSize.Medium,
										Text = line,
										RichText = true,
									},
								},
							}
					end, cleanup),
				},
			},
		},
	}
end
