local Scaler = {}

function Scaler.ScaleModel(model, scale)
	local pivot = model:GetPivot()

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			local rel = pivot:ToObjectSpace(part.CFrame)
			local pos = rel.Position * scale
			local rot = rel - rel.Position
			part.CFrame = pivot * CFrame.new(pos) * rot
		end
	end
end

return Scaler
