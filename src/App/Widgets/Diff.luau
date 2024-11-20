local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Types = require(Argon.Types)
local Theme = require(App.Theme)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local List = require(Components.List)

local AddSnapshot = require(Components.Diff.AddSnapshot)
local UpdateSnapshot = require(Components.Diff.UpdateSnapshot)
local RemoveSnapshot = require(Components.Diff.RemoveSnapshot)

local Children = Fusion.Children
local OnChange = Fusion.OnChange
local ForValues = Fusion.ForValues

type Props = {
    Changes: Types.Changes,
	Closed: (() -> ())?,
}

return function(props: Props): DockWidgetPluginGui
	return Widget {
		Name = "Argon - Diff",
		OverrideEnabled = true,
		MinimumSize = Vector2.new(400, 350),
		Closed = props.Closed,

		[Children] = {
			ScrollingContainer {
				ScrollBar = true,

				[OnChange "CanvasPosition"] = function()
					print("hello")
				end,

				[Children] = {
					List {
						Spacing = 0,
					},

					ForValues(props.Changes.additions, function(use, snapshot)
						return AddSnapshot {
							Snapshot = snapshot,
						}
					end, Fusion.cleanup),
					ForValues(props.Changes.updates, function(use, snapshot)
						return UpdateSnapshot {
							Snapshot = snapshot,
						}
					end, Fusion.cleanup),
					ForValues(props.Changes.removals, function(use, object)
						return RemoveSnapshot {
							Object = object,
						}
					end, Fusion.cleanup),
				}
			},
		},
	}
end
