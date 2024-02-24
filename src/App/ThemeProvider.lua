local plugin = script:FindFirstAncestorWhichIsA('Plugin')
local Studio = settings().Studio

local Argon = script:FindFirstAncestor('Argon')
local App = script:FindFirstAncestor('App')
local Util = script.Parent

local Fusion = require(Argon.Packages.Fusion)

local Enums = require(App.Enums)
local Style = require(App.Style)
local Types = require(Util.Types)

local peek = Fusion.peek
local Value = Fusion.Value
local Computed = Fusion.Computed

local ThemeProvider = {
	IsDark = Value(true),
}

function ThemeProvider:GetColor(
	color: Types.CanBeState<Enums.Color>,
	state: Types.CanBeState<Enum.GuiState>?
): Types.Computed<Color3>
	color = peek(color)

	local colorName = Enums:GetName(Enums.Color, color)

	color = Computed(function(use)
		local isDark = use(self.IsDark)
		return Style.Colors[colorName][isDark and 'Dark' or 'Light']
	end)

	if not state then
		return color :: any
	end

	return Computed(function(use)
		local color = use(color)

		local isDark = use(self.IsDark)
		local state = use(state)
		local h, s, v = color:ToHSV()

		if state == Enum.GuiState.Hover then
			return Color3.fromHSV(h, s, v * (isDark and 1.3 or 0.9))
		elseif state == Enum.GuiState.Press then
			return Color3.fromHSV(h, s, v * (isDark and 1.5 or 0.8))
		else
			return color
		end
	end)
end

do
	local function updateTheme()
		local _, _, v = Studio.Theme:GetColor(Enum.StudioStyleGuideColor.MainBackground):ToHSV()
		ThemeProvider.IsDark:set(v <= 0.6)
	end

	updateTheme()

	local connection = Studio.ThemeChanged:Connect(updateTheme)

	plugin.Unloading:Connect(function()
		connection:Disconnect()
		connection = nil
	end)
end

return ThemeProvider
