-->
-- Hides a model on this client only (other clients and the server still see it), remembering what
-- every part looked like so Show puts it back exactly. Hide can be called again to also catch parts
-- that streamed in after the model was hidden.
local LocalHide = {}

local saved = setmetatable({}, { __mode = "k" }) -- [model] = { [item] = { [property] = value } }

function LocalHide.Hide(model: Instance)
	local items = saved[model] or {}
	saved[model] = items
	for _, item in model:GetDescendants() do
		if items[item] then
			continue
		elseif item:IsA("BasePart") or item:IsA("Decal") or item:IsA("Texture") then
			items[item] = { Transparency = item.Transparency }
			item.Transparency = 1
		elseif
			item:IsA("Beam")
			or item:IsA("ParticleEmitter")
			or item:IsA("Light")
			or item:IsA("Trail")
			or item:IsA("SurfaceGui")
			or item:IsA("BillboardGui")
		then
			items[item] = { Enabled = item.Enabled }
			item.Enabled = false
		end
	end
end

function LocalHide.Show(model: Instance)
	local items = saved[model]
	saved[model] = nil
	for item, properties in items or {} do
		if item.Parent then
			for property, value in properties do
				item[property] = value
			end
		end
	end
end

function LocalHide.Set(model: Instance, hidden: boolean)
	if hidden then
		LocalHide.Hide(model)
	else
		LocalHide.Show(model)
	end
end

function LocalHide.IsHidden(model: Instance): boolean
	return saved[model] ~= nil
end

return LocalHide
