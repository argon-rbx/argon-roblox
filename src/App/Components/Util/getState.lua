local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local Util = script.Parent

local Types = require(Util.Types)

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
