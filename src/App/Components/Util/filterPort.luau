return function(port: string): string
	return port:sub(1, 5):gsub("[^%d]", "")
end
