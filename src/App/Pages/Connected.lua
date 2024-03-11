local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Widgets = App.Widgets

local Fusion = require(Argon.Packages.Fusion)

local Assets = require(App.Assets)
local Theme = require(App.Theme)

local Widget = require(Components.Plugin.Widget)
local ProjectDetails = require(Widgets.ProjectDetails)
local TextButton = require(Components.TextButton)
local IconButton = require(Components.IconButton)
local Container = require(Components.Container)
local Padding = require(Components.Padding)
local Text = require(Components.Text)
local List = require(Components.List)
local Box = require(Components.Box)

local Value = Fusion.Value
local Observer = Fusion.Observer
local Computed = Fusion.Computed
local Children = Fusion.Children
local Cleanup = Fusion.Cleanup
local peek = Fusion.peek

return function(app, project: { [string]: any }): { Instance }
	local syncedText = Value('just now')
	local widget = nil

	local function updateSyncedText()
		return task.spawn(function()
			while true do
				local elapsed = os.time() - peek(app.lastSync)
				local interval = 1
				local text

				if elapsed < 1 then
					text = 'just now'
				elseif elapsed < 60 then
					text = math.floor(elapsed) .. 's ago'
				elseif elapsed < 3600 then
					interval = 60
					text = math.floor(elapsed / interval) .. 'm ago'
				elseif elapsed < 86400 then
					interval = 3600
					text = math.floor(elapsed / interval) .. 'h ago'
				else
					interval = 86400
					text = math.floor(elapsed / interval) .. 'd ago'
				end

				syncedText:set(text)
				task.wait(interval)
			end
		end)
	end

	local thread = updateSyncedText()
	local disconnect = Observer(app.lastSync):onChange(function()
		task.cancel(thread)
		thread = updateSyncedText()
	end)

	return {
		List {},
		Box {
			Size = UDim2.new(1, 0, 0, Theme.CompSizeY * 1.5),
			[Children] = {
				Padding {},
				Text {
					Size = UDim2.fromScale(0.8, 0.6),
					Text = project.name,
					Font = Theme.Fonts.Bold,
					Scaled = true,
				},
				Text {
					Position = UDim2.fromScale(0, 0.6),
					Size = UDim2.fromScale(0.8, 0.4),
					Text = `{app.host}:{app.port}`,
					TextSize = Theme.TextSize - 4,
					Font = Theme.Fonts.Mono,
					Scaled = true,
				},
				Text {
					AnchorPoint = Vector2.new(1, 0.5),
					Position = UDim2.new(1, -2, 0.5, 0),
					Text = Computed(function(use)
						return 'Synced\n' .. use(syncedText)
					end),
					Font = Theme.Fonts.Italic,
					Color = Theme.Colors.TextDimmed,
					TextSize = Theme.TextSize - 4,
					TextXAlignment = Enum.TextXAlignment.Right,
					LineHeight = 1.2,
				},
			},
		},
		Container {
			Size = UDim2.fromScale(1, 0),
			[Children] = {
				List {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Right,
				},
				TextButton {
					Text = 'Disconnect',
					LayoutOrder = 2,
					Solid = true,

					Activated = function()
						app:home()
						app:disconnect()
					end,
				},
				IconButton {
					Icon = Assets.Icons.Settings,
					LayoutOrder = 1,
					Activated = function()
						app:settings()
					end,
				},
				IconButton {
					Icon = Assets.Icons.Info,
					Activated = function()
						if widget then
							widget:Destroy()
						end

						widget = Widget {
							Name = 'Argon - Project Details',
							MinimumSize = Vector2.new(400, 250),

							Closed = function()
								widget:Destroy()
								widget = nil
							end,

							[Children] = ProjectDetails(app, project),
						}
					end,
					[Cleanup] = function()
						if widget then
							widget:Destroy()
							widget = nil
						end

						disconnect()
						task.cancel(thread)
					end,
				},
			},
		},
	}
end
