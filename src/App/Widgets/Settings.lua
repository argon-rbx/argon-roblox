local TextService = game:GetService('TextService')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components

local Fusion = require(Argon.Packages.Fusion)
local Config = require(Argon.Config)

local Assets = require(App.Assets)
local Theme = require(App.Theme)
local Types = require(App.Types)

local TextButton = require(Components.TextButton)
local IconButton = require(Components.IconButton)
local Container = require(Components.Container)
local Input = require(Components.Input)
local Padding = require(Components.Padding)
local List = require(Components.List)
local Text = require(Components.Text)
local Box = require(Components.Box)

local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed
local Children = Fusion.Children
local OnChange = Fusion.OnChange

local SETTINGS_DATA = {
	host = {
		Name = 'Server Host',
		Description = 'The host of the server that you want to connect to',
		Index = 0,
	},
	port = {
		Name = 'Server Port',
		Description = 'The port of the server',
		Index = 1,
	},
}

local function getValueComponent(setting: string)
	local value = Config:getDefault(setting)

	-- if type(value) == 'boolean' then
	-- 	return OptionButton {
	-- 		Options = {
	-- 			{ Text = 'True', Value = true },
	-- 			{ Text = 'False', Value = false },
	-- 		},
	-- 	}
	-- end
end

local function Cell(setting: string): Frame
	local data = SETTINGS_DATA[setting] or {}
	local absoluteSize = Value(Vector2.new())
	local valueComponent = getValueComponent(setting)

	return Box {
		Size = UDim2.new(1, -24, 0, 0),
		LayoutOrder = data.Index or math.huge,
		[Children] = {
			Padding {},
			Text {
				Text = data.Name or setting,
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
					IconButton {
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
	App: Types.App,
}

return function(props: Props): { Instance }
	local cells = {}

	for setting in pairs(Config.DEFAULTS) do
		table.insert(cells, Cell(setting))
	end

	return {
		List {
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},
		unpack(cells),
		-- Box {},
		-- OptionButton {},
	}
end
