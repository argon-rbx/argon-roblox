local database = require(script.database)
local Error = require(script.Error)
local PropertyDescriptor = require(script.PropertyDescriptor)

local function findCanonicalPropertyDescriptor(className, propertyName)
	local currentClassName = className

	repeat
		local currentClass = database.Classes[currentClassName]

		if currentClass == nil then
			return currentClass
		end

		local propertyData = currentClass.Properties[propertyName]
		if propertyData ~= nil then
			local canonicalData = propertyData.Kind.Canonical
			if canonicalData ~= nil then
				return PropertyDescriptor.fromRaw(propertyData, currentClassName, propertyName)
			end

			local aliasData = propertyData.Kind.Alias
			if aliasData ~= nil then
				return PropertyDescriptor.fromRaw(
					currentClass.Properties[aliasData.AliasFor],
					currentClassName,
					aliasData.AliasFor
				)
			end

			return nil
		end

		currentClassName = currentClass.Superclass
	until currentClassName == nil

	return nil
end

local function getDefaultProperties(className)
	local class = database.Classes[className]
	local properties = {}

	if not class then
		return nil
	end

	for property, default in pairs(class.DefaultProperties) do
		local descriptor = findCanonicalPropertyDescriptor(className, property)

		if
			descriptor
			and (descriptor.scriptability == "ReadWrite" or descriptor.scriptability == "Custom")
			and next(default)
		then
			properties[property] = default
		end
	end

	return properties
end

local function isCreatable(className)
	local class = database.Classes[className]

	if not class then
		return false
	end

	return (table.find(class.Tags, "NotCreatable") or table.find(class.Tags, "Service")) == nil
end

local function readProperty(instance, propertyName)
	local descriptor = findCanonicalPropertyDescriptor(instance.ClassName, propertyName)

	if descriptor == nil then
		local fullName = ("%s.%s"):format(instance.className, propertyName)

		return false, Error.new(Error.Kind.UnknownProperty, fullName)
	end

	return descriptor:read(instance)
end

local function writeProperty(instance, propertyName, value)
	local descriptor = findCanonicalPropertyDescriptor(instance.ClassName, propertyName)

	if descriptor == nil then
		local fullName = ("%s.%s"):format(instance.className, propertyName)

		return false, Error.new(Error.Kind.UnknownProperty, fullName)
	end

	return descriptor:write(instance, value)
end

return {
	isCreatable = isCreatable,
	readProperty = readProperty,
	writeProperty = writeProperty,
	findCanonicalPropertyDescriptor = findCanonicalPropertyDescriptor,
	getDefaultProperties = getDefaultProperties,
	Error = Error,
	EncodedValue = require(script.EncodedValue),
}
