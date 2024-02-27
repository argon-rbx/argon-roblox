local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')
local Packages = Argon.Packages
local Components = script.Components
local Widgets = script.Widgets
local Pages = script.Pages

local Fusion = require(Packages.Fusion)

local manifest = require(Argon.manifest)
local Config = require(Argon.Config)
local Client = require(Argon.Client)
local Core = require(Argon.Core)

local Assets = require(script.Assets)
local Theme = require(script.Theme)

local Toolbar = require(Components.Plugin.Toolbar)
local ToolbarButton = require(Components.Plugin.ToolbarButton)
local Widget = require(Components.Plugin.Widget)
local Container = require(Components.Container)
local Image = require(Components.Image)
local Text = require(Components.Text)
local List = require(Components.List)

local NotConnected = require(Pages.NotConnected)
local Settings = require(Widgets.Settings)

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

	self.client = Client.new()
	self.core = Core.new(self.client)

	local isOpen = Value(false)

	local toolbarButton = ToolbarButton {
		Toolbar = Toolbar {
			Name = 'Dervex Tools',
		},
		Name = 'Argon',
		ToolTip = 'Open Argon UI',
		Image = Assets.Argon.Logo,

		[OnEvent 'Click'] = function()
			isOpen:set(not peek(isOpen))
		end,
	}

	Widget {
		Name = 'Argon',
		InitialDockTo = Enum.InitialDockState.Float,
		MinimumSize = Vector2.new(300, 190), -- almost golden rectangle
		Enabled = isOpen,
		[OnChange 'Enabled'] = function(isEnabled)
			isOpen:set(isEnabled)
		end,

		[Children] = {
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
						Color = Theme.Colors.TextDimmed,
						TextSize = 18,
					},
				},
			},
			Container {
				LayoutOrder = 2,
				Size = UDim2.new(1, -36, 0, 0),
				[Children] = {
					NotConnected {
						App = self,
					},
				},
			},
		},
	}

	plugin.Unloading:Connect(Observer(isOpen):onChange(function()
		toolbarButton:SetActive(peek(isOpen))
	end))

	toolbarButton:SetActive(peek(isOpen))

	return self
end

function App:openSettings()
	if self.settingsWidget then
		self.settingsWidget:Destroy()
	end

	self.settingsWidget = Widget {
		Name = 'Argon Settings',
		MinimumSize = Vector2.new(360, 520),

		Closed = function()
			self.settingsWidget:Destroy()
			self.settingsWidget = nil
		end,

		[Children] = Settings(),
	}
end

return App
