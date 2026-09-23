-- Roblox Services
local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local function createImageLabel(parent, props)
	local frame = InstanceCreator("Frame", "GamepadIcon", parent, {
		BackgroundTransparency = 0.08 * GuiService.PreferredTransparency,
		BackgroundColor3 = Color3.fromRGB(18, 18, 21),

		Size = props["Size"] or UDim2.fromScale(0.7, 0.7),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,

		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(1 + (props["Size"].X.Scale / 4), 0.5),

		Visible = props["Visible"],

		Tags = {
			"PreferredTransparency",
		},
	})

	InstanceCreator("UICorner", "UICorner", frame, {
		CornerRadius = UDim.new(1, 0),
	})

	InstanceCreator("UIStroke", "UIStroke", frame, {
		Thickness = 1,
		Color = Color3.fromRGB(255, 255, 255),
	})

	InstanceCreator("ImageLabel", "Vector", frame, {
		Image = props["Image"] or "",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(0.6, 0.6),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})

	return frame
end

return function(button: GuiButton)
	local gamepadLinked = button:HasTag("GamepadLinked")
	if not gamepadLinked then
		return
	end

	local keycodeName = button:GetAttribute("KeycodeName") :: string
	if not TypeCheck.string(keycodeName) then
		return
	end

	local keycode = Enum.KeyCode[keycodeName]
	if not TypeCheck.EnumItem(keycode) then
		return
	end

	createImageLabel(button, {
		Image = UserInputService:GetImageForKeyCode(keycode),
		Size = UDim2.fromScale(0.7, 0.7),
		Visible = UserInputService.GamepadEnabled,
	})
end
