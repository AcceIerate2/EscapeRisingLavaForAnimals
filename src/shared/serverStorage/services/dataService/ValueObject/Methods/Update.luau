local UpdateMethod = {}

UpdateMethod.Key = "Update"
UpdateMethod.IsSupported = function(value: any)
	return typeof(value) == "table"
end

UpdateMethod.Function = function(_self, mutator, dataToUpdate)
	assert(typeof(mutator) == "function", "Update requires a function")
	local cached = _self.DeepCopyDict(_self.Value)
	mutator(cached)
	_self:Set(cached, dataToUpdate)
end

return UpdateMethod
