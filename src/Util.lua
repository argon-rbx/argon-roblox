local Util = {}

function Util.len(table: { any }): number
	local count = 0

	for _ in pairs(table) do
		count += 1
	end

	return count
end

return Util
