-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-->
return function(parent)
	local container = InstanceCreator("Frame", "AlertBadge", parent, {
		BackgroundTransparency = 0,
		BackgroundColor3 = Color3.fromRGB(255, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromOffset(30, 30),
	})

	InstanceCreator("UIStroke", "UIStroke", container, {
		Thickness = 1,
		Color = Color3.fromRGB(255, 255, 255),
	})

	InstanceCreator("UICorner", "UICorner", container, {
		CornerRadius = UDim.new(1, 0),
	})

	local parentTextLabel = InstanceCreator("TextLabel", "Txt", container, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.75, 0.75),
		BackgroundTransparency = 1,
		TextScaled = true,
		FontFace = Font.new("Monsterrat", Enum.FontWeight.Bold, Enum.FontStyle.Italic),
		TextColor3 = Color3.fromRGB(0, 0, 0),
	})

	InstanceCreator("TextLabel", "Txt", parentTextLabel, {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.445),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		TextScaled = true,
		FontFace = Font.new("Monsterrat", Enum.FontWeight.Bold, Enum.FontStyle.Italic),
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})

	return container
end
