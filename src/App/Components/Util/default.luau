return function<T>(value: T?, default: T): T
	if value == nil then
		return default
	else
		return value
	end
end
