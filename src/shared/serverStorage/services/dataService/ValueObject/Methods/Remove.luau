local RemoveMethod = {}

RemoveMethod.Key = "Remove"

RemoveMethod.IsSupported = function(value: any)
	return typeof(value) == "table"
end

RemoveMethod.Function = function(_self, directory, key, reference, referenceKey)
	local cached = _self.DeepCopyDict(_self.Value)
	local target = _self.ResolveTarget(cached, directory, false)

	if target == nil then
		return
	end

	if key ~= nil then
		local entry = target[key]
		if typeof(entry) == "table" and entry.Quantity and entry.Quantity > 1 then
			entry.Quantity -= 1
		else
			target[key] = nil
		end
	elseif reference ~= nil then
		local idx = table.find(target, reference)

		if idx then
			table.remove(target, idx)
		elseif referenceKey ~= nil then
			for i, v in ipairs(target) do
				if typeof(v) == "table" and v[referenceKey] == reference then
					table.remove(target, i)
					break
				end
			end
		end
	else
		return
	end

	_self:Set(cached, {
		Key = key,
	})
end

return RemoveMethod
