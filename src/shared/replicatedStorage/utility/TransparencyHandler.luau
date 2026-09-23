local Module = {}

function Module.setTransparency(asset: BasePart | Model | Folder, transparency: number)
	if not asset then
		error("asset not passed or nil")
	end

	if not transparency then
		error("transparency value not passed or nil")
	end

	if asset:IsA("BasePart") then
		asset:SetAttribute("defaultTransparency", asset.Transparency)
		asset.Transparency = transparency
	end

	local descendants = asset:GetDescendants()
	if #descendants > 0 then
		for _index: number, childInstance: Instance in pairs(descendants) do
			if childInstance:IsA("BasePart") then
				if transparency >= 0 then
					childInstance:SetAttribute("defaultTransparency", childInstance.Transparency)
					childInstance.Transparency = transparency
				else -- pass -1 to reset
					childInstance.Transparency = childInstance:GetAttribute("defaultTransparency") :: number
				end
			end
		end
	end
end

return Module
