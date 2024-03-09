local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local ScrollingContainer = require(Components.ScrollingContainer)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Children = Fusion.Children

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

return function(app, details: { [string]: any }): ScrollingFrame
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
				Value = details.name,
			},
			Entry {
				Name = 'Game ID',
				Value = details.gameId or 'Any',
			},
			Entry {
				Name = 'Place IDs',
				Value = details.placeIds or 'Any',
			},
			Entry {
				Name = 'Synced Directories',
				Value = 'TODO',
			},
			Entry {
				Name = 'Server Version',
				Value = details.version,
			},
			Entry {
				Name = 'Host',
				Value = app.client.host,
			},
			Entry {
				Name = 'Port',
				Value = app.client.port,
			},
		},
	}
end
