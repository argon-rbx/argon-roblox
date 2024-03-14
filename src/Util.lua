local HttpService = game:GetService('HttpService')

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

--- Copy table and all of its subtables
function Util.deepCopy(table: { any }): { any }
	local copy = {}

	for key, value in pairs(table) do
		if type(value) == 'table' then
			copy[key] = Util.deepCopy(value)
		else
			copy[key] = value
		end
	end

	return copy
end

--- Find the key of the provided value in the table
function Util.find(table: { any }, value: any): any?
	for k, v in pairs(table) do
		if v == value then
			return k
		end
	end

	return nil
end

--- Find the value and key of the first element that passes the filter
function Util.filter(table: { any }, filter: (value: any, key: any) -> boolean): (any?, any?)
	for key, value in pairs(table) do
		if filter(value, key) then
			return value, key
		end
	end

	return nil
end

--- Get an array of keys provided dictionary
function Util.keys(dictionary: { any }): { any }
	local keys = {}

	for key in pairs(dictionary) do
		table.insert(keys, key)
	end

	return keys
end

--- Stringify the value
function Util.stringify(value: any): string
	if type(value) == 'table' then
		if Util.len(value) == 0 then
			return '{}'
		end

		local first = next(value)

		if type(first) == 'number' then
			local str = '{'

			for _, v in ipairs(value) do
				str ..= Util.stringify(v) .. ', '
			end

			str = str:sub(1, -3)
			return str .. '}'
		else
			local str = '{\n'

			for k, v in pairs(value) do
				local key = type(k) == 'string' and `"{k}"` or Util.stringify(k)
				local val = type(v) == 'string' and `"{v}"` or Util.stringify(v)

				str ..= `\t[{key}] = {val},\n`
			end

			return str .. '}'
		end
	elseif typeof(value) == 'Instance' then
		return value:GetFullName()
	else
		return tostring(value)
	end
end

--- Truncate the string to the provided length
function Util.truncate(value: string, length: number): string
	if #value > length then
		return value:sub(1, length) .. '... *Truncated*'
	end

	return value
end

--- Generate a GUID, example: 04AEBFEA-87FC-480F-A98B-E5E221007A90
function Util.generateGUID(): string
	return HttpService:GenerateGUID(false)
end

--- Cast the value to the provided type (number, string, boolean, any)
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

--- Clean all provided connections and instances
function Util.clean(...)
	local function clean(object: any)
		local kind = typeof(object)

		if kind == 'function' then
			object()
		elseif kind == 'RBXScriptConnection' then
			object:Disconnect()
		elseif kind == 'Instance' then
			object:Destroy()
		elseif kind == 'table' then
			if typeof(object.Destroy) == 'function' then
				object:Destroy()
			else
				for _, object in pairs(object) do
					clean(object)
				end
			end
		end
	end

	for _, arg in ipairs({ ... }) do
		clean(arg)
	end
end

return Util
