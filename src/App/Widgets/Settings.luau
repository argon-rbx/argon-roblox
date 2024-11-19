local Argon = script:FindFirstAncestor("Argon")
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Config = require(Argon.Config)
local GlobalUtil = require(Argon.Util)

local Theme = require(App.Theme)
local default = require(Util.default)
local filterHost = require(Util.filterHost)
local filterPort = require(Util.filterPort)
local filterNumber = require(Util.filterNumber)
local getTextSize = require(Util.getTextSize)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local OptionSelector = require(Components.OptionSelector)
local Collapsible = require(Components.Collapsible)
local TextButton = require(Components.TextButton)
local Container = require(Components.Container)
local Checkbox = require(Components.Checkbox)
local Dropdown = require(Components.Dropdown)
local Padding = require(Components.Padding)
local Input = require(Components.Input)
local List = require(Components.List)
local Text = require(Components.Text)
local Box = require(Components.Box)

local New = Fusion.New
local Value = Fusion.Value
local Hydrate = Fusion.Hydrate
local Cleanup = Fusion.Cleanup
local Observer = Fusion.Observer
local Computed = Fusion.Computed
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local ForValues = Fusion.ForValues
local ForPairs = Fusion.ForPairs
local peek = Fusion.peek

local SETTINGS_DATA: { { Title: string, Settings: { SettingData } } } = {
	{
		Title = "General",
		Settings = {
			{
				Setting = "InitialSyncPriority",
				Name = "Initial Sync Priority",
				Description = "Which side should be considered as up to date when connecting",
				Options = { "Server", "Client", "None" },
			},
			{
				Setting = "Host",
				Name = "Server Host",
				Description = "The host of the server that you want to connect to",
				Filter = filterHost,
				CustomWidth = 0.31,
			},
			{
				Setting = "Port",
				Name = "Server Port",
				Description = "The port of the server that you want to connect to",
				Filter = filterPort,
				CustomWidth = 70,
			},
		},
	},
	{
		Title = "Automation",
		Settings = {
			{
				Setting = "AutoConnect",
				Name = "Auto Connect",
				Description = "Automatically attempt to connect to the server when you open a new place",
			},
			{
				Setting = "AutoReconnect",
				Name = "Auto Reconnect",
				Description = "If the connection is lost, automatically reconnect to the server after delay",
			},
			{
				Setting = "LiveHydrate",
				Name = "Live Hydrate",
				Description = "If the target instance doesn't exist in Studio, automatically hydrate it with the server",
			},
			{
				Setting = "KeepUnknowns",
				Name = "Keep Unknowns",
				Description = "By default keep instances that are not present in the file system",
			},
		},
	},
	{
		Title = "Syncback",
		Settings = {
			{
				Setting = "TwoWaySync",
				Name = "Two-Way Sync",
				Description = "Sync changes made in Roblox Studio back to the server (local file system)",
			},
			{
				Setting = "SyncbackProperties",
				Name = "Syncback Properties",
				Description = "Whether all properties should be synced back to the server <b>(does not affect scripts)</b>",
			},
			{
				Setting = "OnlyCodeMode",
				Name = "Only Code Mode",
				Description = "Syncback only scripts and instances that have descendant scripts",
			},
			{
				Setting = "OpenInEditor",
				Name = "Open In Editor",
				Description = "Open scripts in your OS default editor instead of the Roblox Studio one",
			},
		},
	},
	{
		Title = "Misc",
		Settings = {
			{
				Setting = "DisplayPrompts",
				Name = "Display Prompts",
				Description = "When to show prompts for actions that require confirmation",
				Options = { "Always", "Initial", "Never" },
			},
			{
				Setting = "ChangesThreshold",
				Name = "Changes Threshold",
				Description = "The maximum number of changes that will be applied before prompting the user",
				Filter = filterNumber,
				CustomWidth = 50,
			},
			{
				Setting = "LogLevel",
				Name = "Log Level",
				Description = "The level of logging you want to see in the output",
				Options = { "Off", "Error", "Warn", "Info", "Debug", "Trace" },
			},
			{
				Setting = "OverridePackages",
				Name = "Override Packages",
				Description = "Whether writing changes to the instances affected by <b>PackageLink</b> should be allowed",
			},
		},
	},
}

local LEVELS = { "Global", "Game", "Place" }

type SettingData = {
	Setting: Config.Setting,
	Name: string,
	Description: string,
	Options: { string }?,
	Filter: ((value: string) -> string)?,
	CustomWidth: number?,
}

type EntryProps = {
	Data: SettingData,
	Level: Fusion.Value<Config.Level>,
	Binding: Fusion.Value<any>,
}

local function Entry(props: EntryProps): Frame
	local setting = props.Data.Setting
	local absoluteSize = Value(Vector2.zero)

	local valueComponent

	if props.Data.Filter then
		local userInput = false

		local disconnect = Observer(props.Binding):onChange(function()
			local value = peek(props.Binding)

			if not userInput and value == Config:getDefault(setting) then
				props.Binding:set("")
			end

			userInput = false
		end)

		if peek(props.Binding) == Config:getDefault(setting) then
			props.Binding:set("")
		end

		valueComponent = Box {
			Size = props.Data.CustomWidth
					and math.floor(props.Data.CustomWidth) == props.Data.CustomWidth
					and UDim2.fromOffset(props.Data.CustomWidth, Theme.CompSizeY.Medium)
				or UDim2.new(props.Data.CustomWidth or 0.2, 0, 0, Theme.CompSizeY.Medium),
			[Children] = {
				Input {
					Size = UDim2.fromScale(1, 1),
					Text = props.Binding,
					PlaceholderText = Config:getDefault(setting),

					Changed = function(text)
						userInput = true
						props.Binding:set(props.Data.Filter(text))
					end,
					Finished = function(text)
						text = text ~= "" and text or Config:getDefault(setting)

						props.Binding:set(text)
						Config:set(setting, text, peek(props.Level))
					end,

					[Children] = {
						Padding {
							Vertical = false,
						},
					},
					[Cleanup] = disconnect,
				},
			},
		}
	elseif props.Data.Options then
		valueComponent = Dropdown {
			Options = props.Data.Options,
			Value = props.Binding,
			Selected = function(value)
				Config:set(setting, value, peek(props.Level))
			end,
		}
	else
		valueComponent = Checkbox {
			Value = props.Binding,
			Changed = function(value)
				Config:set(setting, value, peek(props.Level))
			end,
		}
	end

	return Container {
		ZIndex = props.Data.Options and 2 or 1,
		Size = UDim2.fromScale(1, 0),

		[Children] = {
			New "Frame" {
				Size = UDim2.new(1, 0, 0, Theme.BorderThickness),
				BackgroundColor3 = Theme.Colors.Border,
				BorderSizePixel = 0,
			},
			Container {
				Size = UDim2.fromScale(1, 1),
				[Children] = {
					Padding {},
					Text {
						Text = props.Data.Name,
						Font = Theme.Fonts.Bold,
					},
					Container {
						Size = UDim2.fromScale(1, 0),
						[Children] = {
							List {
								FillDirection = Enum.FillDirection.Horizontal,
								VerticalAlignment = Enum.VerticalAlignment.Center,
								HorizontalFlex = Enum.UIFlexAlignment.Fill,
							},
							Container {
								[Children] = {
									Text {
										RichText = true,
										TextWrapped = true,
										AutomaticSize = Enum.AutomaticSize.None,
										Text = props.Data.Description,
										TextSize = Theme.TextSize.Small,
										Color = Theme.Colors.TextDimmed,
										Position = UDim2.fromOffset(0, 22),

										Size = Computed(function(use)
											local absoluteSize = use(absoluteSize)

											local size = getTextSize(
												props.Data.Description,
												Theme.TextSize.Small,
												Theme.Fonts.Enums.Regular,
												Vector2.new(absoluteSize.X, math.huge)
											)

											return UDim2.new(1, 0, 0, size.Y)
										end),

										[OnChange "AbsoluteSize"] = function(size)
											absoluteSize:set(size)
										end,
									},
								},
							},
							Hydrate(valueComponent) {
								[Children] = {
									New "UIFlexItem" {},
								},
							},
						},
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
	local level = Value("Global")
	local bindings = {}

	return Widget {
		Name = "Argon - Settings",
		OverrideEnabled = true,
		MinimumSize = Vector2.new(350, 400),
		Closed = props.Closed,

		[Children] = {
			Padding {
				Right = 4,
			},

			ScrollingContainer {
				ScrollBar = true,

				[Children] = {
					List {},
					Padding {
						Padding = Theme.WidgetPadding,
					},
					OptionSelector {
						Options = LEVELS,
						Selected = function(option)
							level:set(option)

							for setting, binding in pairs(bindings) do
								binding:set(default(Config:get(setting, option), Config:getDefault(setting)))
							end
						end,
					},
					ForPairs(SETTINGS_DATA, function(_, index, data)
						return index,
							Collapsible {
								Title = `{index}. {data.Title}`,
								Expanded = index == 1,
								Elements = ForValues(data.Settings, function(_, data)
									local setting = data.Setting
									local binding =
										Value(default(Config:get(setting, peek(level)), Config:getDefault(setting)))

									bindings[setting] = binding

									return Entry {
										Data = data,
										Level = level,
										Binding = binding,
									}
								end, Fusion.cleanup),
							}
					end, Fusion.cleanup),
					Container {
						Size = UDim2.fromScale(1, 0),
						LayoutOrder = GlobalUtil.len(SETTINGS_DATA) + 1,
						[Children] = {
							TextButton {
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.fromScale(1, 0),
								Text = "Restore Defaults",
								Activated = function()
									for setting, binding in pairs(bindings) do
										binding:set(Config:getDefault(setting))
									end

									Config:restoreDefaults(peek(level))
								end,
							},
						},
					},
				},
			},
		},
	}
end
