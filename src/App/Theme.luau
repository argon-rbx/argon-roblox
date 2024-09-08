local plugin = script:FindFirstAncestorWhichIsA("Plugin")
local Studio = settings().Studio

local Argon = script:FindFirstAncestor("Argon")

local Fusion = require(Argon.Packages.Fusion)

local Value = Fusion.Value

local function getColors(isDark: boolean): { [string]: { Color3 | { [string]: Color3 } } }
	local border = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Shadow)
	local background = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground)

	return {
		-- It's actually 130, 120, 230
		Brand = Color3.fromRGB(120, 110, 220),

		Background = background,
		ActiveBackground = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.Titlebar),
		Border = border ~= background and border
			or Studio.Theme:GetColor(Enum.StudioStyleGuideColor.ScrollBarBackground),

		Text = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.BrightText),
		TextDimmed = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.SubText),
		TextBranded = isDark and Studio.Theme:GetColor(Enum.StudioStyleGuideColor.BrightText) or background,

		Diff = {
			Add = Color3.fromRGB(80, 220, 100),
			Update = Color3.fromRGB(100, 200, 230),
			Remove = Color3.fromRGB(230, 100, 100),
		},
	}
end

local function init(): Fusion.Value<Color3>
	return Value(Color3.new())
end

local Theme = {
	-- For autocomplete
	Colors = {
		Brand = init(),

		Background = init(),
		ActiveBackground = init(),
		Border = init(),

		Text = init(),
		TextDimmed = init(),
		TextBranded = init(),

		Diff = {
			Add = init(),
			Update = init(),
			Remove = init(),
		},
	},

	Fonts = {
		Regular = Font.fromName("Ubuntu"),
		Bold = Font.fromName("Ubuntu", Enum.FontWeight.Bold),
		Italic = Font.fromName("Ubuntu", Enum.FontWeight.Regular, Enum.FontStyle.Italic),
		Mono = Font.fromName("RobotoMono"),

		-- required for TextService:GetTextSize()
		Enums = {
			Regular = Enum.Font.Ubuntu,
			Bold = Enum.Font.Ubuntu,
			Italic = Enum.Font.Ubuntu,
			Mono = Enum.Font.RobotoMono,
		},
	},

	BorderThickness = 1,
	CornerRadius = 6,
	ListSpacing = 12,
	WidgetPadding = 16,
	Padding = 8,

	TextSize = {
		Large = 20,
		Medium = 18,
		Small = 16,
	},

	CompSizeY = {
		Large = 36,
		Medium = 30,
		Small = 28,
	},

	SpringSpeed = 30,
	SpringDamping = 1.5,

	IsDark = Value(true),
}

do
	local function updateTheme()
		local _, _, v = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground):ToHSV()
		local isDark = v <= 0.6

		Theme.IsDark:set(isDark)

		for key, color in pairs(getColors(isDark)) do
			if type(color) ~= "table" then
				Theme.Colors[key]:set(color)
			else
				for subKey, subColor in pairs(color) do
					Theme.Colors[key][subKey] = subColor
				end
			end
		end
	end

	updateTheme()

	local connection = Studio.ThemeChanged:Connect(updateTheme)

	plugin.Unloading:Once(function()
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
