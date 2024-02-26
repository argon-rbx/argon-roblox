return function(target: any): boolean
	return type(target) == 'table' and target.type == 'State'
end
