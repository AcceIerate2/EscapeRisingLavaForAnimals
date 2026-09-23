-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-- Config
local _TweenInfo = TweenInfo.new(0.1)

local multipliers = {
	Idle = Vector2.new(1, 1),
	Hover = Vector2.new(1.04, 1.04),
	Hold = Vector2.new(0.97, 0.97),
}

local imageColors = {
	OnHover = Color3.fromRGB(200, 200, 200),
	OnLeave = Color3.fromRGB(255, 255, 255),
}

-->
local function toggleImageColor(button: GuiButton, colorType: string)
	if not button:IsA("ImageButton") or button:HasTag("ColorButtonEffectDisabled") then
		return
	end
	button.ImageColor3 = imageColors[colorType]
end

local function getDefaultSize(button: GuiButton)
	local attr = button:GetAttribute("DefaultSize")
	if typeof(attr) == "UDim2" then
		return attr
	end
	local size = button.Size
	button:SetAttribute("DefaultSize", size)
	return size
end

local function scaledSize(defaultSize: UDim2, scale: Vector2)
	return UDim2.new(
		defaultSize.X.Scale * scale.X,
		defaultSize.X.Offset * scale.X,
		defaultSize.Y.Scale * scale.Y,
		defaultSize.Y.Offset * scale.Y
	)
end

local function tween(button: GuiButton, scale: Vector2)
	if button:HasTag("StaticBtn") then
		return
	end

	local base = getDefaultSize(button)
	TweenService:Create(button, _TweenInfo, {
		Size = scaledSize(base, scale),
	}):Play()
end

local function mouseEnter(button: GuiButton)
	toggleImageColor(button, "OnHover")
	tween(button, multipliers.Hover)
	soundHandler:play(SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI"):WaitForChild("Hover"), {
		Parent = SoundService,
		PlayOver = true,
	})
end

local function mouseLeave(button: GuiButton)
	toggleImageColor(button, "OnLeave")
	tween(button, multipliers.Idle)
end

local function hold(button: GuiButton)
	toggleImageColor(button, "OnLeave")
	tween(button, multipliers.Hold)
end

local function onPress(button: GuiButton)
	toggleImageColor(button, "OnHover")
	tween(button, multipliers.Hover)
	soundHandler:play(SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI"):WaitForChild("Click"), {
		Parent = SoundService,
		PlayOver = true,
	})
end

local Animate = {
	ButtonConnections = {},
}

function Animate:connect(button: GuiButton)
	getDefaultSize(button)

	self.ButtonConnections[button] = {}
	local entry = self.ButtonConnections[button]

	table.insert(
		entry,
		button.MouseEnter:Connect(function()
			mouseEnter(button)
		end)
	)

	table.insert(
		entry,
		button.MouseLeave:Connect(function()
			mouseLeave(button)
		end)
	)

	table.insert(
		entry,
		button.MouseButton1Down:Connect(function()
			hold(button)
		end)
	)

	table.insert(
		entry,
		button.MouseButton1Up:Connect(function()
			onPress(button)
		end)
	)
end

function Animate:disconnect(button)
	if not button or not button:IsA("GuiButton") then
		return
	end

	local connections = self.ButtonConnections[button]
	if not TypeCheck.table(connections) then
		return
	end

	for _, connection: RBXScriptConnection in pairs(connections) do
		if not TypeCheck.RBXScriptConnection(connection) then
			continue
		end
		connection:Disconnect()
	end

	self.ButtonConnections[button] = nil
	mouseLeave(button)
end

return Animate
