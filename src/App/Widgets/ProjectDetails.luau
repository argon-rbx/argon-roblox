local StudioService = game:GetService("StudioService")

local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Types = require(Argon.Types)

local Theme = require(App.Theme)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Image = require(Components.Image)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Hydrate = Fusion.Hydrate
local Children = Fusion.Children
local Computed = Fusion.Computed
local ForValues = Fusion.ForValues
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
				Size = UDim2.new(0, 160, 1, 0),
				Text = props.Name,
			},
			Text {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(1, -160, 1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				TextColor3 = Theme.Colors.TextDimmed,
				TextSize = Theme.TextSize.Medium,
				TextWrapped = true,
				Text = props.Value,
			},
		},
	}
end

type IconListEntryProps = {
	Name: string,
	Values: {
		{
			Name: string,
			Icon: {
				Image: string,
				ImageRectOffset: Vector2,
				ImageRectSize: Vector2,
			},
		}
	},
}

local function IconListEntry(props: IconListEntryProps): Frame
	return Box {
		Size = UDim2.fromScale(1, 0),
		[Children] = {
			Padding {},
			Text {
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(0, 160, 1, 0),
				Text = props.Name,
			},
			Container {
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(1, -160, 1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				[Children] = {
					List {
						Spacing = 0,
					},
					ForValues(props.Values, function(_, value)
						return Container {
							Size = UDim2.new(1, 0, 0, Theme.CompSizeY.Small),
							[Children] = {
								Hydrate(Image {
									AnchorPoint = Vector2.new(0, 0.5),
									Position = UDim2.fromScale(0, 0.5),
									Size = UDim2.fromOffset(Theme.TextSize.Large, Theme.TextSize.Large),
								})(value.Icon),
								Text {
									Position = UDim2.fromOffset(Theme.TextSize.Large + 4, 0),
									Size = UDim2.new(1, -(Theme.TextSize.Large + 4), 1, 0),
									TextColor3 = Theme.Colors.TextDimmed,
									TextSize = Theme.TextSize.Medium,
									AutomaticSize = Enum.AutomaticSize.Y,
									TextWrapped = true,
									Text = value.Name,
								},
							},
						}
					end, Fusion.cleanup),
				},
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
		Name = "Argon - Project Details",
		OverrideEnabled = true,
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
						Name = "Name",
						Value = Computed(function(use)
							return use(props.Project).name
						end),
					},
					Entry {
						Name = "Game ID",
						Value = Computed(function(use)
							return use(props.Project).gameId or "Any"
						end),
					},
					Entry {
						Name = "Place IDs",
						Value = Computed(function(use)
							local project = use(props.Project)
							return #project.placeIds > 0 and table.concat(project.placeIds, ", ") or "Any"
						end),
					},
					IconListEntry {
						Name = "Root Instances",
						Values = Computed(function(use)
							use(props.Project)

							local values = {}

							for i, instance in props.App.core.rootInstances do
								values[i] = {
									Name = instance.Name,
									Icon = StudioService:GetClassIcon(instance.ClassName),
								}
							end

							return values
						end),
					},
					Entry {
						Name = "Server Version",
						Value = Computed(function(use)
							return use(props.Project).version
						end),
					},
					Entry {
						Name = "Host",
						Value = peek(props.App.host),
					},
					Entry {
						Name = "Port",
						Value = peek(props.App.port),
					},
				},
			},
		},
	}
end
