local plugin = script:FindFirstAncestorWhichIsA('Plugin')

local Argon = script:FindFirstAncestor('Argon')
local Packages = Argon.Packages
local Components = script.Components
local Widgets = script.Widgets
local Pages = script.Pages

local Fusion = require(Packages.Fusion)
local Signal = require(Argon.Packages.Signal)

local manifest = require(Argon.manifest)
local Config = require(Argon.Config)
local Util = require(Argon.Util)
local Core = require(Argon.Core)
local CoreError = require(Argon.Core.Error)

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
local Prompt = require(Pages.Prompt)
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

	self.core = nil
	self.helpWidget = nil
	self.settingsWidget = nil
	self.host = Config:get('host')
	self.port = Config:get('port')
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

	for id, child in pairs(pages) do
		if child._finished then
			page[id] = nil
			continue
		end

		task.spawn(function()
			child._destructor(child._value)
			child._finished = true
		end)
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

		for _, v in ipairs(page:GetDescendants()) do
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

	pages[Util.generateGUID()] = page
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

function App:prompt(message: string, options: { string }): string
	local signal = Signal.new()

	self:setPage(Prompt(message, options, signal))

	return signal:Wait()
end

function App:onStatusChange(status: Core.Status)
	if status == Core.Status.Conntected then
		self:setPage(Connected(self, self.core.project))
	elseif status == Core.Status.Disconnected then
		self:home()
	elseif status == Core.Status.Error then
		self:setPage(Error(self, 'TODO'))
	end
end

function App:connect()
	local errored = false

	self.core = Core.new()

	task.spawn(function()
		task.wait(0.15)

		if self.core.status ~= Core.Status.Conntected and not errored then
			self:setPage(Connecting(self))
		end
	end)

	self.core:setPromptHandler(function(message, options)
		return self:prompt(message, options)
	end)
	self.core:setStatusChangeHandler(function(status)
		self:onStatusChange(status)
	end)

	self.core:run():catch(function(err)
		errored = true

		if err == CoreError.GameId or err == CoreError.PlaceIds or err == CoreError.TooManyChanges then
			self:home()
			return
		end

		self:setPage(Error(self, err.message or tostring(err)))
	end)
end

function App:disconnect()
	self.core:stop()
	self.core = nil
end

function App:setHost(host: string)
	self.host = host
end

function App:setPort(port: number)
	self.port = port
end

return App
