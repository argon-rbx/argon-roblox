return {
	Colors = {
		Background = {
			Dark = Color3.fromRGB(45, 45, 45),
			Light = Color3.fromRGB(250, 250, 250),
		},
		Brand = {
			Dark = Color3.fromRGB(130, 120, 230),
			Light = Color3.fromRGB(130, 120, 230),
		},
		Text = {
			Dark = Color3.fromRGB(250, 250, 250),
			Light = Color3.fromRGB(20, 20, 20),
		},

		BackgroundDimmed = {
			Dark = Color3.fromRGB(85, 85, 85),
			Light = Color3.fromRGB(170, 170, 170),
		},
		BrandDimmed = {
			Dark = Color3.fromRGB(130, 120, 230),
			Light = Color3.fromRGB(130, 120, 230),
		},
		TextDimmed = {
			Dark = Color3.fromRGB(160, 160, 160),
			Light = Color3.fromRGB(20, 20, 20),
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
	TextSize = 20,
	YSize = 36,
}
