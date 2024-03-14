local Argon = script:FindFirstAncestor('Argon')

local Types = require(Argon.Types)

local LENGTH = 38

return function(): Types.Ref
	local id = ''

	for i = 1, LENGTH do
		if i == 1 then
			id ..= math.random(1, 9)
		else
			id ..= math.random(0, 9)
		end
	end

	return id
end
