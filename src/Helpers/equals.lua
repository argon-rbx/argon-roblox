local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

local function equals(a: any, b: any): boolean
	if a == b then
		return true
	end

	local tA, tB = typeof(a), typeof(b)

	if tA == 'table' and tB == 'table' then
		if #a ~= #b or Util.len(a) ~= Util.len(b) then
			return false
		end

		for kA, vA in pairs(a) do
			local found = false

			for kB, vB in pairs(b) do
				if equals(kA, kB) then
					if not equals(vA, vB) then
						return false
					end

					found = true
					break
				end
			end

			if not found then
				return false
			end
		end

		return true
	elseif tA == 'EnumItem' and tB == 'number' then
		return a.Value == b
	elseif tA == 'number' and tB == 'EnumItem' then
		return a == b.Value
	end

	return false
end

return equals
