--!strict
local Argon = script:FindFirstAncestor("Argon")

local Util = require(Argon.Util)

local function fuzzy(a: number, b: number): boolean
	return math.abs(a - b) < 0.0001
end

local function componentEq(a: { number }, b: { number }): boolean
	for i, aComp in a do
		if not fuzzy(aComp, b[i]) then
			return false
		end
	end

	return true
end

local function equals(a: any, b: any): boolean
	if a == b then
		return true
	end

	local tA, tB = typeof(a), typeof(b)

	if tA == "number" and tB == "number" then
		return fuzzy(a, b)
	elseif tA == "CFrame" and tB == "CFrame" then
		return componentEq({ a:components() }, { b:components() })
	elseif tA == "Vector3" and tB == "Vector3" then
		return componentEq({ a.X, a.Y, a.Z }, { b.X, b.Y, b.Z })
	elseif tA == "Vector2" and tB == "Vector2" then
		return componentEq({ a.X, a.Y }, { b.X, b.Y })
	elseif tA == "Color3" and tB == "Color3" then
		return componentEq({ a.R, a.G, a.B }, { b.R, b.G, b.B })
	elseif tA == "EnumItem" and tB == "number" then
		return a.Value == b
	elseif tA == "number" and tB == "EnumItem" then
		return a == b.Value
	elseif tA == "table" and tB == "table" then
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
	elseif tA == "buffer" and tB == "buffer" then
		return buffer.tostring(a) == buffer.tostring(b)
	end

	return false
end

return equals
