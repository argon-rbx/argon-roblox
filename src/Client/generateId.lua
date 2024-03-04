local LENGTH = 10

return function(): number
	return math.floor(math.random() * 10 ^ LENGTH)
end
