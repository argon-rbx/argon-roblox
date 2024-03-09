local TextService = game:GetService('TextService')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local GlobalUtil = require(Argon.Util)
local Config = require(Argon.Config)
local Log = require(Argon.Log)

local Theme = require(App.Theme)
local default = require(Util.default)
local filterHost = require(Util.filterHost)
local filterPort = require(Util.filterPort)

local ScrollingContainer = require(Components.ScrollingContainer)
local OptionSelector = require(Components.OptionSelector)
local TextButton = require(Components.TextButton)
local Container = require(Components.Container)
local Checkbox = require(Components.Checkbox)
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

local SETTINGS_DATA = {
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
		Setting = 'AutoConnect',
		Name = 'Auto Connect',
		Description = 'Automatically attempt to connect to the server when you open a new place',
	},
	{
		Setting = 'OpenInEditor',
		Name = 'Open In Editor',
		Description = 'Open scripts in your OS default editor instead of the Roblox Studio one',
	},
	{
		Setting = 'TwoWaySync',
		Name = 'Two-Way Sync',
		Description = 'Sync changes made in Roblox Studio back to the server (local file system)',
	},
	{
		Setting = 'TwoWaySyncProperties',
		Name = 'Sync Properties',
		Description = 'Whether all properties should be synced back to the server',
		Requires = 'TwoWaySync',
	},
	{
		Setting = 'LogLevel',
		Name = 'Log Level',
		Description = 'The level of logging that you want to see in the output',
		Options = GlobalUtil.keys(Log.Level),
	},
	{
		Setting = 'SyncInterval',
		Name = 'Sync Interval',
		Description = 'The interval between each sync request in seconds',
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

type Props = {
	Data: SettingData,
	Level: Fusion.Value<Config.Level>,
	Binding: Fusion.Value<any>,
	Requires: Fusion.Value<boolean>?,
}

local function Entry(props: Props): Frame
	local setting = props.Data.Setting
	local absoluteSize = Value(Vector2.new())

	local valueComponent

	if setting == 'Host' or setting == 'Port' or setting == 'SyncInterval' then
		local size
		if setting == 'Host' then
			size = UDim2.new(0.31, 0, 0, Theme.CompSizeY - 6)
		elseif setting == 'Port' then
			size = UDim2.fromOffset(70, Theme.CompSizeY - 6)
		else
			size = UDim2.fromOffset(53, Theme.CompSizeY - 6)
		end

		local onChanged
		if setting == 'Host' then
			onChanged = filterHost
		elseif setting == 'Port' then
			onChanged = filterPort
		else
			onChanged = function(text)
				return text:sub(1, 4):gsub('[^%d%.]', '')
			end
		end

		local onFinished
		if setting == 'SyncInterval' then
			onFinished = function(text)
				local number = tonumber(text)

				if not number then
					return Config:getDefault(setting)
				end

				return math.clamp(number, 0.15, 60)
			end
		else
			onFinished = function(text)
				return text ~= '' and text or Config:getDefault(setting)
			end
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
						text = onFinished(text)

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
		-- TODO: dropdown component
		print(props.Data.Options)
		valueComponent = Container {}
	else
		valueComponent = Checkbox {
			Value = props.Binding,
			Changed = function(value)
				Config:set(setting, value, peek(props.Level))
			end,
		}
	end

	return Box {
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
								TextWrapped = true,
								AutomaticSize = Enum.AutomaticSize.None,
								Text = props.Data.Description,
								TextSize = Theme.TextSize - 4,
								Color = Theme.Colors.TextDimmed,
								Position = UDim2.fromOffset(0, 22),

								Size = Computed(function(use)
									local absoluteSize = use(absoluteSize)

									local size = TextService:GetTextSize(
										props.Data.Description,
										Theme.TextSize - 4,
										Theme.Fonts.Enum,
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

return function(): ScrollingFrame
	local level = Value('Global')
	local bindings = {}

	return ScrollingContainer {
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

				return Entry {
					Data = data,
					Level = level,
					Binding = binding,
					Requires = bindings[data.Requires],
				}
			end, Fusion.cleanup),
			Container {
				Size = UDim2.fromScale(1, 0),
				LayoutOrder = math.huge,
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
	}
end
