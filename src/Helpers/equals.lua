local Argon = script:FindFirstAncestor('Argon')

local Util = require(Argon.Util)

local function fuzzy(a: number, b: number): boolean
	return math.abs(a - b) < 0.001
end

local function equals(a: any, b: any): boolean
	if a == b then
		return true
	end

	local tA, tB = typeof(a), typeof(b)

	if tA == 'number' and tB == 'number' then
		return fuzzy(a, b)
	elseif tA == 'EnumItem' and tB == 'number' then
		return a.Value == b
	elseif tA == 'number' and tB == 'EnumItem' then
		return a == b.Value
	elseif tA == 'table' and tB == 'table' then
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
	end

	return false
end

return equals
