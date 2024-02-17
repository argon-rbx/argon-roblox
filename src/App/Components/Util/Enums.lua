export type Color = 'Primary' | 'Accent' | 'Dimmed' | 'Text'
export type Font = 'Default' | 'Bold' | 'Italic' | 'Mono'
export type ButtonState = 'Default' | 'Hovered' | 'Pressed'

local Enums = {
	Color = {
		Primary = 1,
		Accent = 2,
		Dimmed = 3,
		Text = 4,
	},
	Font = {
		Default = 1,
		Bold = 2,
		Italic = 3,
		Mono = 4,
	},
	ButtonState = {
		Default = 1,
		Hovered = 2,
		Pressed = 3,
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
