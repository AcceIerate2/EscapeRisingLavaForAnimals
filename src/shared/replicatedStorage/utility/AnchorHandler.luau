local TypeCheck = require(script.Parent.TypeCheck)
return function(asset: BasePart | Model | Folder, toggle: boolean)
	if not asset or not TypeCheck.boolean(toggle) then
		return
	end

	if asset:IsA("BasePart") then
		asset.Anchored = toggle
	end

	local descendants = asset:GetDescendants()

	if #descendants > 0 then
		for _index: number, childInstance: Instance in pairs(descendants) do
			if childInstance:IsA("BasePart") then
				childInstance.Anchored = toggle
			end
		end
	end
end
