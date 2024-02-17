local Argon = script:FindFirstAncestor('Argon')
local Fusion = require(Argon.Packages.Fusion)

local Enums = require(script.Parent.Enums)
local Types = require(script.Parent.Types)

local Computed = Fusion.Computed

type Input = {
	Pressed: Types.CanBeState<boolean>?,
	Hovered: Types.CanBeState<boolean>?,
}

return function(input: Input): Types.Computed<Enums.ButtonState>
	local isPressed = input.Pressed
	local isHovered = input.Hovered

	return Computed(function(use)
		if use(isPressed) then
			return Enums.ButtonState.Pressed
		elseif use(isHovered) then
			return Enums.ButtonState.Hovered
		else
			return Enums.ButtonState.Default
		end
	end)
end
