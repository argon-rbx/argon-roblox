return function(host: string): string
	return host:gsub("[^%w%.%-]", "")
end
