local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Types = require(Argon.Types)

local Theme = require(App.Theme)

local ScrollingContainer = require(Components.ScrollingContainer)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Children = Fusion.Children
local Computed = Fusion.Computed
local peek = Fusion.peek

type Props = {
	Name: string,
	Value: string,
}

local function Entry(props: Props): Frame
	return Box {
		Size = UDim2.fromScale(1, 0),
		[Children] = {
			Padding {},
			Text {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(0.5, 1),
				Text = props.Name,
			},
			Text {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.5, 1),
				Text = props.Value,
			},
		},
	}
end

return function(app, details: Fusion.Value<Types.ProjectDetails>): ScrollingFrame
	print(details)
	return ScrollingContainer {
		[Children] = {
			List {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			},
			Padding {
				Padding = Theme.WidgetPadding,
			},
			Entry {
				Name = 'Name',
				Value = Computed(function(use)
					return use(details).name
				end),
			},
			Entry {
				Name = 'Game ID',
				Value = Computed(function(use)
					return use(details).gameId or 'Any'
				end),
			},
			Entry {
				Name = 'Place IDs',
				Value = Computed(function(use)
					local details = use(details)
					return #details.placeIds > 0 and table.concat(details.placeIds, ', ') or 'Any'
				end),
			},
			Entry {
				Name = 'Synced Directories',
				Value = 'TODO',
			},
			Entry {
				Name = 'Server Version',
				Value = Computed(function(use)
					return use(details).version
				end),
			},
			Entry {
				Name = 'Host',
				Value = peek(app.host),
			},
			Entry {
				Name = 'Port',
				Value = peek(app.port),
			},
		},
	}
end
