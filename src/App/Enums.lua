export type Color = 'Background' | 'Brand' | 'Text' | 'BackgroundDimmed' | 'BrandDimmed' | 'TextDimmed'
export type Font = 'Default' | 'Bold' | 'Italic' | 'Mono'

local Enums = {
	Color = {
		Background = 1,
		Brand = 2,
		Text = 3,
		BackgroundDimmed = 4,
		BrandDimmed = 5,
		TextDimmed = 6,
	},
	Font = {
		Default = 1,
		Bold = 2,
		Italic = 3,
		Mono = 4,
	},
}

function Enums:GetName(parent: { [string]: { number } }, item: any): string
	for name, value in pairs(parent) do
		if value == item then
			return name
		end
	end

	return ''
end

return Enums
