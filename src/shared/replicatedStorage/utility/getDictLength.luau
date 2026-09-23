return function(dict: {}): number
	local length = 0
	for _, _v: any in pairs(dict) do
		length += 1
	end
	return length
end
