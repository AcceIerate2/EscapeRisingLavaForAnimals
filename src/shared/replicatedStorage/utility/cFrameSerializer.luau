local CFrameSerializer = {}

function CFrameSerializer.Serialize(cf)
	return { cf:GetComponents() }
end

function CFrameSerializer.Deserialize(t)
	return CFrame.new(unpack(t))
end

return CFrameSerializer
