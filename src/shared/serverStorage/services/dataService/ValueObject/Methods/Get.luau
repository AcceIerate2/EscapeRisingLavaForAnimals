local GetMethod = {}

GetMethod.Key = "Get"
GetMethod.IsSupported = function(_: any)
	return true
end

GetMethod.Function = function(_self)
	return typeof(_self["Value"]) == "table" and _self.DeepCopyDict(_self["Value"]) or _self["Value"]
end

return GetMethod
