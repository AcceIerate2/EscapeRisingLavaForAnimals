local InsertMethod = {}

InsertMethod.Key = "Insert"
InsertMethod.IsSupported = function(value: any)
	return typeof(value) == "table"
end

InsertMethod.Function = function(_self, directory, key, data)
	local cached = _self.DeepCopyDict(_self.Value)
	local target = _self.ResolveTarget(cached, directory)

	if key then
		local entry = target[key]
		if entry and entry.Quantity then
			entry.Quantity += 1
		else
			target[key] = data
		end
	else
		table.insert(target, data)
	end

	_self:Set(cached, {
		Key = key,
	})
end

return InsertMethod
