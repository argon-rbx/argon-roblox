local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)

local Theme = require(App.Theme)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Input = require(Components.Input)
local List = require(Components.List)
local Text = require(Components.Text)
local Box = require(Components.Box)

local Children = Fusion.Children

local function Entry(body: { any })
	return Box {
		Size = UDim2.fromScale(1, 0),
		[Children] = {
			Padding {},
			List {
				Spacing = 6,
			},
			body,
		},
	}
end

local function Header(text: string)
	return Text {
		Font = Theme.Fonts.Bold,
		Text = text,
	}
end

local function Paragraph(text: string)
	return Text {
		Text = text,
		TextWrapped = true,
		TextSize = Theme.TextSize.Small,
		Color = Theme.Colors.TextDimmed,
	}
end

local function Link(text: string, url: string)
	return Container {
		Size = UDim2.fromScale(1, 0),
		[Children] = {
			List {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Spacing = 8,
			},
			Text {
				Font = Theme.Fonts.Bold,
				Text = text,
			},
			Box {
				AutomaticSize = Enum.AutomaticSize.XY,
				[Children] = {
					Padding {},
					Input {
						AutomaticSize = Enum.AutomaticSize.XY,
						Text = url,
						TextEditable = false,
						TextSize = Theme.TextSize.Large,
					},
				},
			},
		},
	}
end

type Props = {
	Closed: (() -> ())?,
}

return function(props: Props): DockWidgetPluginGui
	return Widget {
		Name = "Argon - Help",
		OverrideEnabled = true,
		MinimumSize = Vector2.new(400, 350),
		Closed = props.Closed,

		[Children] = {
			Padding {
				Right = 4,
			},

			ScrollingContainer {
				ScrollBar = true,

				[Children] = {
					List {
						Spacing = 22,
					},
					Padding {
						Padding = Theme.WidgetPadding,
					},
					Link("Visit official website to learn more:", "https://argon.wiki"),
					Entry {
						Header "1. Setting up the project",
						Paragraph 'First you need to create new Argon project. If you are using CLI run "argon init" command.',
						Paragraph 'If you are using VS Code extension open command palette (ctrl/cmd + shift + P) and run "Argon: Open Menu" -> "Init".',
					},
					Entry {
						Header "2. Starting the server",
						Paragraph 'To start the server run "argon serve" command in your terminal or use "Argon: Open Menu" -> "Serve" command in VS Code.',
					},
					Entry {
						Header "3. Connecting to the server",
						Paragraph 'To connect to the server first make sure that host name and port are the same. Then press "Connect" button and you are done!',
					},
					Entry {
						Header "4. Syncing",
						Paragraph "Now you can finally start syncing your changes. Remember to save your files in order to see the changes in Roblox Studio.",
						Paragraph "You can also enable Two-Way Sync in the settings to sync changes made in Studio back to the file system.",
					},
				},
			},
		},
	}
end
