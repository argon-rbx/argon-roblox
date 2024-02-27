local TextService = game:GetService('TextService')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)
local Config = require(Argon.Config)

local Theme = require(App.Theme)
local Types = require(App.Types)
local default = require(Util.default)
local filterHost = require(Util.filterHost)
local filterPort = require(Util.filterPort)

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
local Computed = Fusion.Computed
local Children = Fusion.Children
local OnChange = Fusion.OnChange
local ForPairs = Fusion.ForPairs
local peek = Fusion.peek

local SETTINGS_DATA = {
	host = {
		Name = 'Server Host',
		Description = 'The host of the server that you want to connect to',
		Index = 1,
	},
	port = {
		Name = 'Server Port',
		Description = 'The port of the server that you want to connect to',
		Index = 2,
	},
	autoConnect = {
		Name = 'Auto Connect',
		Description = 'Automatically attempt to connect to the server when you open a new place',
		Index = 3,
	},
	openInEditor = {
		Name = 'Open In Editor',
		Description = 'Open scripts in your OS default editor instead of the Roblox Studio one',
		Index = 4,
	},
	twoWaySync = {
		Name = 'Two-Way Sync',
		Description = 'Sync changes made in Roblox Studio back to the server (local file system)',
		Index = 5,
	},
}

local LEVELS = { 'Global', 'Game', 'Place' }

type Props = {
	Setting: string,
	Level: Types.Value<Config.Level>,
	Binding: Types.Value<any>,
}

local function Cell(props: Props): Frame
	local data = SETTINGS_DATA[props.Setting] or {}
	local absoluteSize = Value(Vector2.new())
	local valueType = type(peek(props.Binding))

	local valueComponent

	if props.Setting == 'host' or props.Setting == 'port' then
		local isHost = props.Setting == 'host'
		local filter = isHost and filterHost or filterPort
		local userInput = false

		valueComponent = Box {
			Size = isHost and UDim2.new(0.29, 0, 0, Theme.CompSizeY - 6) or UDim2.fromOffset(70, Theme.CompSizeY - 6),
			[Children] = {
				Input {
					Size = UDim2.fromScale(1, 1),
					Text = Computed(function(use)
						local binding = use(props.Binding)

						if binding == Config:getDefault(props.Setting) and not userInput then
							return ''
						end

						userInput = false

						return binding
					end),
					Scaled = isHost,
					PlaceholderText = Config:getDefault(props.Setting),

					Changed = function(text)
						userInput = true
						props.Binding:set(filter(text))
					end,

					Finished = function(text)
						if text ~= '' then
							Config:set(props.Setting, text, peek(props.Level))
						end
					end,

					[Children] = {
						Padding {
							Vertical = false,
						},
					},
				},
			},
		}
	elseif valueType == 'string' then
		-- TODO: dropdown when needed
		valueComponent = Container {}
	else
		valueComponent = Checkbox {
			Value = props.Binding,
			Changed = function(value)
				Config:set(props.Setting, value, peek(props.Level))
			end,
		}
	end

	return Box {
		Size = UDim2.fromScale(1, 0),
		LayoutOrder = data.Index or math.huge,
		[Children] = {
			Padding {},
			Text {
				Text = data.Name or props.Setting,
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
								TextXAlignment = Enum.TextXAlignment.Left,
								Text = data.Description or 'No description',
								TextSize = Theme.TextSize - 4,
								Color = Theme.Colors.TextDimmed,
								Position = UDim2.fromOffset(0, 22),

								Size = Computed(function(use)
									local absoluteSize = use(absoluteSize)

									local size = TextService:GetTextSize(
										data.Description or 'No description',
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

	return New 'ScrollingFrame' {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromScale(0, 0),

		[Children] = {
			List {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			},
			Padding {
				Padding = 16,
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
			ForPairs(Config.DEFAULTS, function(_, setting)
				local binding = Value(default(Config:get(setting, peek(level)), Config:getDefault(setting)))

				bindings[setting] = binding

				return setting, Cell {
					Setting = setting,
					Level = level,
					Binding = binding,
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
