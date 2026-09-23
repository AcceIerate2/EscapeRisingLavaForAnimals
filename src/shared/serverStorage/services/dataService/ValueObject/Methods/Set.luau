local SetMethod = {}

SetMethod.Key = "Set"
SetMethod.IsSupported = function(_: any)
	return true
end

SetMethod.Function = function(_self, newValue, dataToUpdate)
	_self.Value = newValue
	_self.Profile[_self.Key] = newValue
	_self.BindableEvent:Fire(newValue)

	if typeof(dataToUpdate) == "table" and dataToUpdate.Key ~= nil then
		_self.UpdateClient(_self.Key, nil, {
			Key = dataToUpdate.Key,
			NewValue = newValue[dataToUpdate.Key],
		})
	else
		_self.UpdateClient(_self.Key, newValue)
	end
end

return SetMethod
