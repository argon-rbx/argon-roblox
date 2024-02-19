local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local App = script:FindFirstAncestor('App')

local Components = App.Components

local Enums = require(App.Enums)
local Style = require(App.Style)
local Assets = require(App.Assets)

local TextButton = require(Components.TextButton)
local IconButton = require(Components.IconButton)
local Container = require(Components.Container)
local Input = require(Components.Input)
local List = require(Components.List)
local Text = require(Components.Text)
local Box = require(Components.Box)

local Value = Fusion.Value
local Children = Fusion.Children
local OnChange = Fusion.OnChange

type Props = {
	[any]: any,
}

local function filterHost(host: string): string
	return host:gsub('[^%w%.%-]', '')
end

local function filterPort(port: string): string
	return port:sub(1, 5):gsub('[^%d]', '')
end

return function(_props: Props): { Instance }
	local host = Value('')
	local port = Value('')

	return {
		List {},
		Box {
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(1, 0, 0, Style.YSize),
			[Children] = {
				Input {
					AnchorPoint = Vector2.new(0, 0.5),
					Position = UDim2.new(0, 10, 0.5, 0),
					Size = UDim2.fromScale(0.75, 1),
					Font = Enums.Font.Mono,
					PlaceholderText = 'localhost',
					Text = host,

					[OnChange 'Text'] = function(text)
						host:set(filterHost(text))
					end,
				},
				Input {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -10, 0.5, 0),
					Size = UDim2.fromScale(0, 1),
					Font = Enums.Font.Mono,
					PlaceholderText = '8000',
					Text = port,

					[OnChange 'Text'] = function(text)
						port:set(filterPort(text))
					end,

					[Children] = {
						Text {
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.fromScale(0, 0.5),
							Text = ': ',
							Font = Enums.Font.Mono,
							Color = Enums.Color.TextDimmed,
						},
					},
				},
			},
		},
		Container {
			LayoutOrder = 1,
			Size = UDim2.fromScale(1, 0),
			[Children] = {
				List {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				TextButton {
					Solid = true,
					LayoutOrder = 1,
					Text = 'Connect',
					Size = UDim2.fromOffset(96, Style.YSize),
					Activated = function()
						print('Button clicked!')
					end,
				},

				IconButton {
					Icon = Assets.Icons.Settings,
				},
			},
		},
	}
end
