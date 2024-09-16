return function(number: string): string
	return number:gsub("[^%d]", "")
end
