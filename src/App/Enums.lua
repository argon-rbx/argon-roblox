export type Color = 'Brand' | 'Background' | 'Border' | 'Text' | 'TextDimmed'
export type Font = 'Default' | 'Bold' | 'Italic' | 'Mono'

local Enums = {
	Color = {
		Brand = 1,
		Background = 2,
		Border = 3,
		Text = 4,
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
