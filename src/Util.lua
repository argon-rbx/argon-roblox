local Util = {}

function Util.len(table: { any }): number
	local count = 0

	for _ in pairs(table) do
		count += 1
	end

	return count
end

function Util.cast(value: any, target: any): any
	if type(value) == target then
		return value
	end

	if target == 'number' then
		return tonumber(value)
	elseif target == 'string' then
		return tostring(value)
	elseif target == 'boolean' then
		return value == 'true'
	else
		return value
	end
end

return Util
