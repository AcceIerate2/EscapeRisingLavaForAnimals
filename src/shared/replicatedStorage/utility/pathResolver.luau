local PathResolver = {}

function PathResolver.find(rootTable, path)
	if type(path) == "string" then
		path = string.split(path, ".")
	end

	local node = rootTable

	for _, key in ipairs(path) do
		node = node[key]
		if node == nil then
			return nil
		end
	end

	return node
end

return PathResolver
