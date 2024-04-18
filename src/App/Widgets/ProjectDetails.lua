local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Types = require(Argon.Types)

local Theme = require(App.Theme)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Children = Fusion.Children
local Computed = Fusion.Computed
local peek = Fusion.peek

type EntryProps = {
	Name: string,
	Value: string,
}

local function Entry(props: EntryProps): Frame
	return Box {
		Size = UDim2.fromScale(1, 0),
		[Children] = {
			Padding {},
			Text {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(0, 180, 1, 0),
				Text = props.Name,
			},
			Text {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(1, -180, 1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextWrapped = true,
				Text = props.Value,
			},
		},
	}
end

type Props = {
	App: { [string]: any },
	Project: Fusion.Value<Types.Project>,
	Closed: (() -> ())?,
}

return function(props: Props): DockWidgetPluginGui
	return Widget {
		Name = 'Argon - Project Details',
		MinimumSize = Vector2.new(410, 300),
		Closed = props.Closed,

		[Children] = {
			Padding {
				Right = 4,
			},

			ScrollingContainer {
				ScrollBar = true,

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
							return use(props.Project).name
						end),
					},
					Entry {
						Name = 'Game ID',
						Value = Computed(function(use)
							return use(props.Project).gameId or 'Any'
						end),
					},
					Entry {
						Name = 'Place IDs',
						Value = Computed(function(use)
							local project = use(props.Project)
							return #project.placeIds > 0 and table.concat(project.placeIds, ', ') or 'Any'
						end),
					},
					Entry {
						Name = 'Synced Dirs',
						Value = Computed(function(use)
							local rootDirs = {}

							for i, id in ipairs(use(props.Project).rootDirs) do
								rootDirs[i] = props.App.core.tree:getInstance(id).Name
							end

							return table.concat(rootDirs, ', ')
						end),
					},
					Entry {
						Name = 'Server Version',
						Value = Computed(function(use)
							return use(props.Project).version
						end),
					},
					Entry {
						Name = 'Host',
						Value = peek(props.App.host),
					},
					Entry {
						Name = 'Port',
						Value = peek(props.App.port),
					},
				},
			},
		},
	}
end
