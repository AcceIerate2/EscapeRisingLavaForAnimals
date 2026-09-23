local DestroyMethod = {}

DestroyMethod.Key = "Destroy"
DestroyMethod.IsSupported = function(_: any)
	return true
end

DestroyMethod.Function = function(_self)
	_self.BindableEvent:Destroy()
	_self.BindableEvent = nil
	_self.Changed = nil
	_self.Key = nil
	_self.Value = nil
	_self.Profile = nil
	_self.Get = nil
	_self.Set = nil
	_self.Destroy = nil
end

return DestroyMethod
