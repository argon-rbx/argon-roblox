return {
	Colors = {
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
	},

	Fonts = {
		Default = Font.fromName('Ubuntu'),
		Bold = Font.fromName('Ubuntu', Enum.FontWeight.Bold),
		Italic = Font.fromName('Ubuntu', Enum.FontWeight.Regular, Enum.FontStyle.Italic),
		Mono = Font.fromName('RobotoMono'),
	},

	CornerRadius = UDim.new(0, 6),
	Padding = UDim.new(0, 12),
	BorderThickness = 1,
	CompSizeY = 36,
	TextSize = 20,
}
