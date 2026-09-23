local function deepClone(value, seen)
	if type(value) ~= "table" then
		return value
	end

	seen = seen or {}
	if seen[value] then
		return seen[value]
	end

	local copy = {}
	seen[value] = copy

	for k, v in pairs(value) do
		copy[deepClone(k, seen)] = deepClone(v, seen)
	end

	return copy
end

return deepClone
