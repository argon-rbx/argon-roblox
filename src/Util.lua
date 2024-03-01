local Util = {}

--- Get length of non-numerically indexed table
function Util.len(table: { any }): number
	local count = 0

	for _ in pairs(table) do
		count += 1
	end

	return count
end

--- Join second table to the first one
function Util.join(table1: { any }, table2: { any }): { any }
	for _, value in pairs(table2) do
		table.insert(table1, value)
	end

	return table1
end

function Util.arrayToString(array: { any }): string
	local str = '['

	for _, value in ipairs(array) do
		str ..= tostring(value) .. ', '
	end

	str = str:sub(1, -3)

	return str .. ']'
end

--- Find the key of the provided value in the dictionary
function Util.findDictionary(dictionary: { [any]: any }, value: any): any?
	for k, v in pairs(dictionary) do
		if v == value then
			return k
		end
	end

	return nil
end

--- Cast the value to the provided type
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
