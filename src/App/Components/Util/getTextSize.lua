local TextService = game:GetService('TextService')

local Argon = script:FindFirstAncestor('Argon')
local App = Argon.App

local Theme = require(App.Theme)

return function(text: string, fontSize: number?, font: Enum.Font?, frameSize: Vector2?): Vector2
	return TextService:GetTextSize(
		text,
		fontSize or Theme.TextSize,
		font or Theme.Fonts.Enum,
		frameSize or Vector2.new(math.huge, math.huge)
	)
end
