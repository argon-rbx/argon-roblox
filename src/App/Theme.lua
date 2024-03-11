local plugin = script:FindFirstAncestorWhichIsA('Plugin')
local Studio = settings().Studio

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App
local Components = App.Components
local Util = Components.Util

local Fusion = require(Argon.Packages.Fusion)

local isState = require(Util.isState)

local Value = Fusion.Value

local COLOR_MAP = {
	Brand = {
		Dark = Color3.fromRGB(120, 100, 220),
		Light = Color3.fromRGB(120, 100, 220),
	},
	Background = {
		Dark = Color3.fromRGB(45, 45, 45),
		Light = Color3.fromRGB(250, 250, 250),
	},
	Border = {
		Dark = Color3.fromRGB(85, 85, 85),
		Light = Color3.fromRGB(170, 170, 170),
	},
	Text = {
		Dark = Color3.fromRGB(250, 250, 250),
		Light = Color3.fromRGB(20, 20, 20),
	},
	TextDimmed = {
		Dark = Color3.fromRGB(160, 160, 160),
		Light = Color3.fromRGB(90, 90, 90),
	},
	Diff = {
		Add = Color3.fromRGB(80, 220, 100),
		Update = Color3.fromRGB(100, 200, 230),
		Remove = Color3.fromRGB(230, 100, 100),
	},
}

local Theme = {
	Colors = {
		Brand = Value(COLOR_MAP.Brand.Dark),
		Background = Value(COLOR_MAP.Background.Dark),
		Border = Value(COLOR_MAP.Border.Dark),
		Text = Value(COLOR_MAP.Text.Dark),
		TextDimmed = Value(COLOR_MAP.TextDimmed.Dark),
		Diff = COLOR_MAP.Diff,
	},

	Fonts = {
		Regular = Font.fromName('Ubuntu'),
		Bold = Font.fromName('Ubuntu', Enum.FontWeight.Bold),
		Italic = Font.fromName('Ubuntu', Enum.FontWeight.Regular, Enum.FontStyle.Italic),
		Mono = Font.fromName('RobotoMono'),
		-- required for TextService:GetTextSize()
		Enums = {
			Regular = Enum.Font.Ubuntu,
			Bold = Enum.Font.Ubuntu,
			Italic = Enum.Font.Ubuntu,
			Mono = Enum.Font.RobotoMono,
		},
	},

	CornerRadius = 6,
	ListSpacing = 12,
	Padding = 8,

	BorderThickness = 1,
	WidgetPadding = 16,
	CompSizeY = 36,
	TextSize = 20,

	SpringSpeed = 30,
	SpringDamping = 1.5,

	IsDark = Value(true),
}

do
	local function updateTheme()
		local _, _, v = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground):ToHSV()
		local isDark = v <= 0.6
		local asString = isDark and 'Dark' or 'Light'

		Theme.IsDark:set(isDark)

		for key, color in pairs(Theme.Colors) do
			if isState(color) then
				color:set(COLOR_MAP[key][asString])
			end
		end
	end

	updateTheme()

	local connection = Studio.ThemeChanged:Connect(updateTheme)

	plugin.Unloading:Connect(function()
		connection:Disconnect()
		connection = nil
	end)

	-- :P
	local now = DateTime.now():ToLocalTime()
	if now.Month == 4 and now.Day == 1 then
		Theme.CornerRadius = 0
	end
end

return Theme
