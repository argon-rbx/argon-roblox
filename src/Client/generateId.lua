local LENGTH = 10

return function(): number
	local id = ''

	for i = 1, LENGTH do
		if i == 1 then
			id ..= math.random(1, 9)
		else
			id ..= math.random(0, 9)
		end
	end

	return tonumber(id) :: number
end
