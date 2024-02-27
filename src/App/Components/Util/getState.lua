local Argon = script:FindFirstAncestor('Argon')

local Fusion = require(Argon.Packages.Fusion)

local Computed = Fusion.Computed

type Input = {
	Pressed: Fusion.StateObject<boolean>?,
	Hovered: Fusion.StateObject<boolean>?,
}

return function(input: Input): Fusion.Computed<Enum.GuiState>
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
