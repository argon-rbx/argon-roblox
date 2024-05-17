local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local Config = require(Argon.Config)

local Theme = require(App.Theme)
local default = require(Util.default)
local filterHost = require(Util.filterHost)
local filterPort = require(Util.filterPort)
local getTextSize = require(Util.getTextSize)

local Widget = require(Components.Plugin.Widget)
local ScrollingContainer = require(Components.ScrollingContainer)
local OptionSelector = require(Components.OptionSelector)
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
local peek = Fusion.peek

local SETTINGS_DATA: { SettingData } = {
	{
		Setting = 'Host',
		Name = 'Server Host',
		Description = 'The host of the server that you want to connect to',
	},
	{
		Setting = 'Port',
		Name = 'Server Port',
		Description = 'The port of the server that you want to connect to',
	},
	{
		Setting = 'InitialSyncPriority',
		Name = 'Initial Sync Priority',
		Description = 'Which side should be considered as up to date when connecting',
		Options = { 'Server', 'Client' },
	},
	{
		Setting = 'OnlyCodeMode',
		Name = 'Only Code Mode',
		Description = 'Initially only sync scripts and instances that have descendant scripts',
		Requires = 'InitialSyncPriority=Client',
	},
	{
		Setting = 'AutoConnect',
		Name = 'Auto Connect',
		Description = 'Automatically attempt to connect to the server when you open a new place',
	},
	{
		Setting = 'AutoReconnect',
		Name = 'Auto Reconnect',
		Description = 'If the connection is lost, automatically reconnect to the server after delay',
	},
	{
		Setting = 'DisplayPrompts',
		Name = 'Display Prompts',
		Description = 'When to show prompts for actions that require confirmation',
		Options = { 'Always', 'Initial', 'Never' },
	},
	{
		Setting = 'TwoWaySync',
		Name = 'Two-Way Sync',
		Description = 'Sync changes made in Roblox Studio back to the server (local file system)',
	},
	{
		Setting = 'TwoWaySyncProperties',
		Name = 'Sync Properties',
		Description = 'Whether all properties should be synced back to the server <b>(does not affect scripts)</b>',
		Requires = 'TwoWaySync',
	},
	{
		Setting = 'OpenInEditor',
		Name = 'Open In Editor',
		Description = 'Open scripts in your OS default editor instead of the Roblox Studio one',
	},
	{
		Setting = 'LogLevel',
		Name = 'Log Level',
		Description = 'The level of logging you want to see in the output',
		Options = { 'Off', 'Error', 'Warn', 'Info', 'Debug', 'Trace' },
	},
	{
		Setting = 'KeepUnknowns',
		Name = 'Keep Unknowns',
		Description = 'By default keep instances that are not present in the file system',
	},
	{
		Setting = 'SkipInitialSync',
		Name = 'Skip Initial Sync',
		Description = 'Skip the initial sync when connecting to the server <b>(only recommended for large places)</b>',
	},
}

local LEVELS = { 'Global', 'Game', 'Place' }

type SettingData = {
	Setting: Config.Setting,
	Name: string,
	Description: string,
	Requires: Config.Setting?,
	Options: { string }?,
}

type EntryProps = {
	Data: SettingData,
	Level: Fusion.Value<Config.Level>,
	Binding: Fusion.Value<any>,
	Requires: Fusion.Value<boolean>?,
}

local function Entry(props: EntryProps): Frame
	local setting = props.Data.Setting
	local absoluteSize = Value(Vector2.new())

	local valueComponent

	if setting == 'Host' or setting == 'Port' then
		local size
		if setting == 'Host' then
			size = UDim2.new(0.31, 0, 0, Theme.CompSizeY.Medium)
		else
			size = UDim2.fromOffset(70, Theme.CompSizeY.Medium)
		end

		local onChanged
		if setting == 'Host' then
			onChanged = filterHost
		else
			onChanged = filterPort
		end

		local userInput = false

		local disconnect = Observer(props.Binding):onChange(function()
			local value = peek(props.Binding)

			if not userInput and value == Config:getDefault(setting) then
				props.Binding:set('')
			end

			userInput = false
		end)

		if peek(props.Binding) == Config:getDefault(setting) then
			props.Binding:set('')
		end

		valueComponent = Box {
			Size = size,
			[Children] = {
				Input {
					Size = UDim2.fromScale(1, 1),
					Text = props.Binding,
					Scaled = setting == 'Host',
					PlaceholderText = Config:getDefault(setting),

					Changed = function(text)
						userInput = true
						props.Binding:set(onChanged(text))
					end,
					Finished = function(text)
						text = text ~= '' and text or Config:getDefault(setting)

						props.Binding:set(text)
						Config:set(setting, text, peek(props.Level))
					end,

					[Children] = {
						Padding {
							Vertical = false,
						},
						-- Temporary
						Text {
							Position = UDim2.new(1, 26, 0, 14),
							TextSize = Theme.TextSize.Small,
							Color = Theme.Colors.TextDimmed,
							AutomaticSize = Enum.AutomaticSize.None,
							Text = setting == 'Host'
									and 'Broken UI?\n1. Go to File > Beta Features\n2. Enable "UIListLayout Flex"\n3. Restart Roblox Studio'
								or '',
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

	return Box {
		ZIndex = props.Data.Options and 2 or 1,
		Size = UDim2.fromScale(1, 0),
		Visible = Computed(function(use)
			return default(use(props.Requires), true)
		end),

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

								[OnChange 'AbsoluteSize'] = function(size)
									absoluteSize:set(size)
								end,
							},
						},
					},
					Hydrate(valueComponent) {
						[Children] = {
							New 'UIFlexItem' {},
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
	local level = Value('Global')
	local bindings = {}

	return Widget {
		Name = 'Argon - Settings',
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
					ForValues(SETTINGS_DATA, function(_, data)
						local setting = data.Setting
						local binding = Value(default(Config:get(setting, peek(level)), Config:getDefault(setting)))

						bindings[setting] = binding

						local requireBinding

						if data.Requires and data.Requires:find('=') then
							local name, value = data.Requires:match('(%a+)=(%w+)')

							requireBinding = Computed(function(use)
								return use(bindings[name]) == value
							end)
						else
							requireBinding = bindings[data.Requires]
						end

						return Entry {
							Data = data,
							Level = level,
							Binding = binding,
							Requires = requireBinding,
						}
					end, Fusion.cleanup),
					Container {
						Size = UDim2.fromScale(1, 0),
						LayoutOrder = #SETTINGS_DATA + 1,
						[Children] = {
							TextButton {
								AnchorPoint = Vector2.new(1, 0),
								Position = UDim2.fromScale(1, 0),
								Text = 'Restore Defaults',
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
