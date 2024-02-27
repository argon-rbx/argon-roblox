local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')
local Packages = Argon.Packages
local Components = script.Components
local Widgets = script.Widgets
local Pages = script.Pages

local Fusion = require(Packages.Fusion)

local manifest = require(Argon.manifest)
local Client = require(Argon.Client)
local Core = require(Argon.Core)

local Assets = require(script.Assets)
local Theme = require(script.Theme)

local Toolbar = require(Components.Plugin.Toolbar)
local ToolbarButton = require(Components.Plugin.ToolbarButton)
local Widget = require(Components.Plugin.Widget)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Image = require(Components.Image)
local Text = require(Components.Text)
local List = require(Components.List)

local NotConnected = require(Pages.NotConnected)
local Connecting = require(Pages.Connecting)
local Connected = require(Pages.Connected)
local Error = require(Pages.Error)

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

	self.page = Value(NotConnected(self))

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
		MinimumSize = Vector2.new(300, 200),
		Enabled = isOpen,
		[OnChange 'Enabled'] = function(isEnabled)
			isOpen:set(isEnabled)
		end,

		[Children] = {
			List {
				VerticalAlignment = Enum.VerticalAlignment.Center,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			},
			Padding {
				Padding = Theme.WidgetPadding,
			},
			Container {
				Size = UDim2.fromScale(1, 0),
				[Children] = {
					Image {
						Size = UDim2.fromOffset(200, 50),
						Image = Assets.Argon.Banner,
					},
					Text {
						AnchorPoint = Vector2.new(1, 1),
						Position = UDim2.new(1, -4, 1, -2),
						Text = `v{manifest.package.version}`,
						Color = Theme.Colors.TextDimmed,
						TextSize = Theme.TextSize - 2,
					},
				},
			},
			Container {
				Size = UDim2.fromScale(1, 0),
				[Children] = self.page,
			},
		},
	}

	plugin.Unloading:Connect(Observer(isOpen):onChange(function()
		toolbarButton:SetActive(peek(isOpen))
	end))

	toolbarButton:SetActive(peek(isOpen))

	return self
end

function App:home()
	self.page:set(NotConnected(self))
end

function App:settings()
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

function App:help()
	-- TODO
end

function App:connect()
	self.page:set(Connecting(self))

	self.client
		:subscribe()
		:andThen(function(details)
			self.page:set(Connected(self, details))
		end)
		:catch(function(err)
			self.page:set(Error(self, err))
		end)
end

function App:disconnect()
	self.client:unsubscribe()
	self:home()
end

function App:setHost(host: string)
	self.client:setHost(host)
end

function App:setPort(port: number)
	self.client:setPort(port)
end

return App
