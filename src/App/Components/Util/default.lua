return function(prop: any, default: any): any
	if prop == nil then
		return default
	else
		return prop
	end
end
