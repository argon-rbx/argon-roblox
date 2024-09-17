--!strict
local HttpService = game:GetService("HttpService")

local Util = {}

--- Get length of non-numerically indexed table
function Util.len(table: { [any]: any }): number
	local count = 0

	for _ in pairs(table) do
		count += 1
	end

	return count
end

--- Join second table to the first one
function Util.join<T>(table1: { T }, table2: { T }): { T }
	for _, value in pairs(table2) do
		table.insert(table1, value)
	end

	return table1
end

--- Convert dictionary to array, ignoring keys
function Util.dictionaryToArray(dictionary: { [any]: any }, __lastArray: { any }?): { any }
	local array = __lastArray or {}

	for _, value in pairs(dictionary) do
		if type(value) == "table" then
			Util.dictionaryToArray(value, array)
		else
			table.insert(array, value)
		end
	end

	return array
end

--- Find the value and key of the first element that passes the filter
function Util.filter<K, V>(table: { [K]: V }, filter: (value: V, key: K) -> boolean): (V?, K?)
	for key, value in pairs(table) do
		if filter(value, key) then
			return value, key
		end
	end

	return nil
end

--- Stringify the value (pretty print)
function Util.stringify(value: any, __indent: number?): string
	if type(value) == "table" then
		local meta = getmetatable(value)

		if meta and meta.__tostring then
			return tostring(value)
		end

		if not next(value) then
			return "{}"
		end

		local first = next(value)

		if type(first) == "number" then
			local containsTable = false

			for _, v in ipairs(value) do
				if type(v) == "table" then
					containsTable = true
					break
				end
			end

			if not containsTable then
				return "{" .. table.concat(value, ", ") .. "}"
			end

			local str = "{\n"
			local indent = __indent and __indent + 1 or 1

			for i, v in ipairs(value) do
				str ..= str.rep("\t", indent)
				str ..= `[{i}] = {Util.stringify(v, indent)},\n`
			end

			return str .. string.rep("\t", indent - 1) .. "}"
		else
			local str = "{\n"
			local indent = __indent and __indent + 1 or 1

			for k, v in pairs(value) do
				local key = type(k) == "string" and `"{k}"` or Util.stringify(k, indent)
				local val = type(v) == "string" and `"{v}"` or Util.stringify(v, indent)

				str ..= str.rep("\t", indent)
				str ..= `[{key}] = {val},\n`
			end

			return str .. string.rep("\t", indent - 1) .. "}"
		end
	elseif typeof(value) == "Instance" then
		return value:GetFullName()
	elseif type(value) == "buffer" then
		return buffer.tostring(value) .. " (buffer)"
	else
		return tostring(value)
	end
end

--- Generate a GUID, example: 04AEBFEA-87FC-480F-A98B-E5E221007A90
function Util.generateGUID(): string
	return HttpService:GenerateGUID(false)
end

--- Cast the value to the provided type (number, string, boolean, any)
function Util.cast(value: any, target: string): any
	if type(value) == target then
		return value
	end

	if target == "number" then
		return tonumber(value)
	elseif target == "string" then
		return tostring(value)
	elseif target == "boolean" then
		return value == "true"
	else
		return value
	end
end

--- Clean all provided connections and instances
function Util.clean(...: () -> () | RBXScriptConnection | Instance | { [any]: any })
	local function clean(object: any)
		local kind = typeof(object)

		if kind == "function" then
			object()
		elseif kind == "RBXScriptConnection" then
			object:Disconnect()
		elseif kind == "Instance" then
			object:Destroy()
		elseif kind == "table" then
			if typeof(object.Destroy) == "function" then
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

function Util.isPackageDescendant(instance: Instance): boolean
	repeat
		if instance:FindFirstChildWhichIsA("PackageLink") then
			return true
		end

		instance = instance.Parent or game
	until instance == game

	return false
end

return Util
