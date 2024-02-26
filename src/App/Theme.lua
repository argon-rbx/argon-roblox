local plugin = script:FindFirstAncestorWhichIsA('Plugin')
local Studio = settings().Studio

local Argon = script:FindFirstAncestor('Argon')

local Fusion = require(Argon.Packages.Fusion)

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
}

local Theme = {
	Colors = {
		Brand = Value(COLOR_MAP.Brand.Dark),
		Background = Value(COLOR_MAP.Background.Dark),
		Border = Value(COLOR_MAP.Border.Dark),
		Text = Value(COLOR_MAP.Text.Dark),
		TextDimmed = Value(COLOR_MAP.TextDimmed.Dark),
	},

	Fonts = {
		Enum = Enum.Font.Ubuntu, -- required for TextService:GetTextSize()
		Regular = Font.fromName('Ubuntu'),
		Bold = Font.fromName('Ubuntu', Enum.FontWeight.Bold),
		Italic = Font.fromName('Ubuntu', Enum.FontWeight.Regular, Enum.FontStyle.Italic),
		Mono = Font.fromName('RobotoMono'),
	},

	CornerRadius = UDim.new(0, 6),
	ListSpacing = UDim.new(0, 12),
	Padding = UDim.new(0, 8),

	BorderThickness = 1,
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
			color:set(COLOR_MAP[key][asString])
		end
	end

	updateTheme()

	local connection = Studio.ThemeChanged:Connect(updateTheme)

	plugin.Unloading:Connect(function()
		connection:Disconnect()
		connection = nil
	end)
end

return Theme
