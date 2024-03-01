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
local Padding = require(Components.Padding)
local Image = require(Components.Image)
local Text = require(Components.Text)
local List = require(Components.List)

local NotConnected = require(Pages.NotConnected)
local Connecting = require(Pages.Connecting)
local Connected = require(Pages.Connected)
local Error = require(Pages.Error)

local Settings = require(Widgets.Settings)
local Help = require(Widgets.Help)

local New = Fusion.New
local Value = Fusion.Value
local Spring = Fusion.Spring
local OnEvent = Fusion.OnEvent
local OnChange = Fusion.OnChange
local Observer = Fusion.Observer
local Computed = Fusion.Computed
local Children = Fusion.Children
local cleanup = Fusion.cleanup
local peek = Fusion.peek

local App = {}
App.__index = App

function App.new()
	local self = setmetatable({}, App)

	self.client = Client.new()
	self.core = Core.new(self.client)

	self.pages = Value({})

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
		MinimumSize = Vector2.new(300, 190),
		Enabled = isOpen,
		[OnChange 'Enabled'] = function(isEnabled)
			isOpen:set(isEnabled)
		end,

		[Children] = self.pages,
	}

	plugin.Unloading:Connect(Observer(isOpen):onChange(function()
		toolbarButton:SetActive(peek(isOpen))
	end))

	toolbarButton:SetActive(peek(isOpen))

	self:setPage(NotConnected(self))

	if Config:get('autoConnect') then
		self:connect()
	end

	return self
end

function App:setPage(page)
	local pages = peek(self.pages)
	local toRemove = {}

	for i, child in ipairs(pages) do
		if child._finished then
			table.insert(toRemove, i)
			continue
		end

		task.spawn(function()
			child._destructor(child._value)
			child._finished = true
		end)
	end

	for _, i in ipairs(toRemove) do
		table.remove(pages, i)
	end

	local transparency = Value(0)
	local size = Value(UDim2.fromScale(1, 1))

	page = Computed(function()
		return New 'CanvasGroup' {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			BackgroundColor3 = Theme.Colors.Background,
			BorderSizePixel = 0,
			GroupTransparency = Spring(transparency, 25),
			Size = Spring(size, 5),
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
							Size = UDim2.fromOffset(160, 40),
							Image = Assets.Argon.Banner,
						},
						Text {
							AnchorPoint = Vector2.new(1, 1),
							Position = UDim2.new(1, -5, 1, -2),
							Text = `v{manifest.package.version}`,
							Color = Theme.Colors.TextDimmed,
							TextSize = Theme.TextSize - 4,
						},
					},
				},
				Container {
					Size = UDim2.fromScale(1, 0),
					[Children] = page,
				},
			},
		}
	end, function(page)
		if not page then
			return
		end

		for _, v in page:GetDescendants() do
			if v:IsA('GuiButton') then
				v.Active = false
			end
		end

		page.ZIndex = math.huge

		transparency:set(1)
		size:set(UDim2.fromScale(2, 1.2))
		task.wait(0.15)

		cleanup(page)
	end)

	table.insert(pages, page)

	self.pages:set(pages)
end

function App:home()
	self:setPage(NotConnected(self))
end

function App:settings()
	if self.settingsWidget then
		self.settingsWidget:Destroy()
	end

	self.settingsWidget = Widget {
		Name = 'Argon - Settings',
		MinimumSize = Vector2.new(350, 400),

		Closed = function()
			self.settingsWidget:Destroy()
			self.settingsWidget = nil
		end,

		[Children] = Settings(),
	}
end

function App:help()
	if self.helpWidget then
		self.helpWidget:Destroy()
	end

	self.helpWidget = Widget {
		Name = 'Argon - Help',
		MinimumSize = Vector2.new(400, 350),

		Closed = function()
			self.helpWidget:Destroy()
			self.helpWidget = nil
		end,

		[Children] = Help(),
	}
end

function App:connect()
	-- self:setPage(Connecting(self))
	self.core:init()

	-- self.client
	-- 	:subscribe()
	-- 	:andThen(function(details)
	-- 		self:setPage(Connected(self, details))

	-- 		self.client:readAll():andThen(function(data)
	-- 			-- print(data)
	-- 		end)
	-- 	end)
	-- 	:catch(function(err)
	-- 		self:setPage(Error(self, err))
	-- 	end)
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
