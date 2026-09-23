local ClearMethod = {}

ClearMethod.Key = "Clear"
ClearMethod.IsSupported = function(value: any)
	return typeof(value) == "table"
end

ClearMethod.Function = function(_self, directory)
	local cached = _self.DeepCopyDict(_self.Value)

	if directory ~= nil then
		cached[directory] = {}
	else
		table.clear(cached)
	end

	_self:Set(cached)
end

return ClearMethod
