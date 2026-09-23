-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Config
local backgroundTransparency = 0.35
local backgroundColor3 = Color3.fromRGB(0, 0, 0)

local frames = {
	Left = {
		Size = UDim2.fromScale(1 / 3, 1),
		Position = UDim2.fromScale(0, 0.5),
	},

	Right = {
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.fromScale(1 / 3, 1),
	},

	Top = {
		Position = UDim2.fromScale(0.5, 0),
		Size = UDim2.fromScale(1 / 3, 0.25),
	},

	Bottom = {
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1 / 3, 0.25),
	},

	Placeholder = {
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1 / 3, 0.5),
	},
}

-->
return function(player: Player, id: string)
	local container = InstanceCreator("ScreenGui", "Highlighter", player.PlayerGui, {
		SafeAreaCompatibility = Enum.SafeAreaCompatibility.None,
		ScreenInsets = Enum.ScreenInsets.None,
		ClipToDeviceArea = false,
	}) :: ScreenGui

	local tutorialGui = player.PlayerGui:WaitForChild("Tutorial") :: ScreenGui
	container.DisplayOrder = tutorialGui.DisplayOrder - 1

	for frameName: string, props: { [string]: any } in pairs(frames) do
		props.BackgroundTransparency = backgroundTransparency
		props.BackgroundColor3 = backgroundColor3
		props.BorderSizePixel = 0

		local frame = InstanceCreator("Frame", frameName, container, props) :: Frame

		if frameName == "Placeholder" then
			frame.ZIndex = 2
			frame.BackgroundTransparency = 1

			InstanceCreator("UIStroke", "UIStroke", frame, {
				StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
				Thickness = 0.01,
				Color = Color3.fromRGB(255, 255, 255),
			})

			InstanceCreator("UICorner", "UICorner", frame, {
				CornerRadius = 0.05,
			})
		end
	end

	return container
end
