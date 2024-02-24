local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Packages = script.Parent.Packages
local Components = script.Components
local Pages = script.Pages

local Fusion = require(Packages.Fusion)
local Config = require(script.Parent.Config)
local Enums = require(script.Enums)
local Assets = require(script.Assets)
local manifest = require(script.Parent.manifest)

local Toolbar = require(Components.Plugin.Toolbar)
local ToolbarButton = require(Components.Plugin.ToolbarButton)
local Widget = require(Components.Plugin.Widget)
local Container = require(Components.Container)
local Image = require(Components.Image)
local Text = require(Components.Text)
local List = require(Components.List)

local NotConnected = require(Pages.NotConnected)

local Value = Fusion.Value
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Children = Fusion.Children
local peek = Fusion.peek

local App = {}
App.__index = App

function App.new()
	local self = setmetatable({}, App)

	local defaultSize = Vector2.new(330, 190)

	local isOpen = Value(false)
	local title = Value('Argon')

	local toolbar = Toolbar {
		Name = 'Dervex Tools',
	}

	local toolbarButton = ToolbarButton {
		Toolbar = toolbar,
		Name = 'Argon',
		ToolTip = 'Open Argon UI',
		Image = Assets.Argon.Logo,

		[OnEvent 'Click'] = function()
			isOpen:set(not peek(isOpen))
		end,
	}

	plugin.Unloading:Connect(Observer(isOpen):onChange(function()
		toolbarButton:SetActive(peek(isOpen))
	end))

	Widget {
		Name = title,

		InitialEnabled = true,
		FloatingSize = defaultSize,
		MinimumSize = defaultSize,

		Enabled = isOpen,
		[OnChange 'Enabled'] = function(isEnabled)
			isOpen:set(isEnabled)
		end,

		[Children] = self:render(),
	}

	return self
end

function App:render()
	return {
		List {
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
		},
		Container {
			Size = UDim2.new(1, -24, 0, 0),
			[Children] = {
				Image {
					Size = UDim2.fromOffset(200, 50),
					Image = Assets.Argon.Banner,
				},
				Text {
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, -10, 1, -2),
					Text = `v{manifest.package.version}`,
					Color = Enums.Color.TextDimmed,
					Font = Enums.Font.Default,
					TextSize = 18,
				},
			},
		},
		Container {
			LayoutOrder = 2,
			Size = UDim2.new(1, -36, 0, 0),
			[Children] = {
				NotConnected {},
			},
		},
	}
end

return App
