return {
	Colors = {
		Primary = {
			Dark = Color3.fromRGB(45, 45, 45),
			Light = Color3.fromRGB(250, 250, 250),
		},
		Accent = {
			Dark = Color3.fromRGB(130, 120, 230),
			Light = Color3.fromRGB(130, 120, 230),
		},
		Dimmed = {
			Dark = Color3.fromRGB(85, 85, 85),
			Light = Color3.fromRGB(170, 170, 170),
		},
		Text = {
			Dark = Color3.fromRGB(250, 250, 250),
			Light = Color3.fromRGB(20, 20, 20),
		},
	},

	Fonts = {
		Default = Font.fromName('Ubuntu'),
		Bold = Font.fromName('Ubuntu', Enum.FontWeight.Bold),
		Italic = Font.fromName('Ubuntu', Enum.FontWeight.Regular, Enum.FontStyle.Italic),
		Mono = Font.fromName('Code'),
	},

	CornerRadius = UDim.new(0, 6),
	BorderThickness = 1,
	TextSize = 18,
}
