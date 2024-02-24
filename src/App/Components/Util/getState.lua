local Argon = script:FindFirstAncestor('Argon')
local App = script:FindFirstAncestor('App')

local Fusion = require(Argon.Packages.Fusion)

local Types = require(App.Types)

local Computed = Fusion.Computed

type Input = {
	Pressed: Types.CanBeState<boolean>?,
	Hovered: Types.CanBeState<boolean>?,
}

return function(input: Input): Types.Computed<Enum.GuiState>
	local isPressed = input.Pressed
	local isHovered = input.Hovered

	return Computed(function(use)
		if use(isPressed) then
			return Enum.GuiState.Press
		elseif use(isHovered) then
			return Enum.GuiState.Hover
		else
			return Enum.GuiState.Idle
		end
	end)
end
