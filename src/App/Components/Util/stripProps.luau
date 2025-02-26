return function(props: { [any]: any }, strip: { string }): { [any]: any }
	props = table.clone(props)

	for _, prop in strip do
		props[prop] = nil
	end

	return props
end
