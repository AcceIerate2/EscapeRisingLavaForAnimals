return function(Part: BasePart): Model | nil
	if not Part or not Part:IsA("BasePart") then
		return
	end

	if Part.Parent and Part.Parent.Parent then
		local Humanoid = Part.Parent:FindFirstChildOfClass("Humanoid")
		if Humanoid then
			return Humanoid.Parent
		else
			Humanoid = Part.Parent.Parent:FindFirstChildOfClass("Humanoid")
			if Humanoid then
				return Humanoid.Parent
			end
		end
	end

	return nil
end
