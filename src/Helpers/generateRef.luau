local Argon = script:FindFirstAncestor("Argon")

local Types = require(Argon.Types)

return function(asString: boolean?): Types.Ref
	local buf = buffer.create(16)

	for i = 0, 15 do
		buffer.writeu8(buf, i, math.random(0, 255))
	end

	return asString and buffer.tostring(buf) or buf
end
