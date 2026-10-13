-- Roblox Services
local Debris = game:GetService("Debris")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Utility
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)
local Spring = require(ReplicatedStorage.src.utility.Spring)

-- Config
local hoverTweenInfo = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local pressTweenInfo = TweenInfo.new(0.075, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local releaseTweenInfo = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local rippleTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local multipliers = { Idle = 1, Hover = 1.04, Hold = 0.95 }
local hoverSpring = { Rotation = 3, Damping = 0.72, Frequency = 5.5 }

-- Helper Functions
local function getDefaultSize(button: GuiButton)
	local attr = button:GetAttribute("DefaultSize")
	if typeof(attr) == "UDim2" then
		return attr
	end
	button:SetAttribute("DefaultSize", button.Size)
	return button.Size
end

local function playSound(name: string)
	local src = SoundService:FindFirstChild("src")
	local sfx = src and src:FindFirstChild("Sfx")
	local ui = sfx and sfx:FindFirstChild("UI")
	local sound = ui and ui:FindFirstChild(name)
	if sound then
		soundHandler:play(sound, { Parent = SoundService, PlayOver = true })
	end
end

local function updateAppearance(button: GuiButton, entry, tweenInfo: TweenInfo)
	local highlighted = entry.Selected
		or (entry.Hovered and UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse)
	if button:IsA("ImageButton") and not button:HasTag("ColorButtonEffectDisabled") then
		button.ImageColor3 = if highlighted and not entry.Pressed
			then entry.ImageColor:Lerp(Color3.new(0, 0, 0), 0.12)
			else entry.ImageColor
	end
	if entry.Tween then
		entry.Tween:Cancel()
		entry.Tween = nil
	end
	if button:HasTag("StaticBtn") then
		return
	end
	Spring.target(button, hoverSpring.Damping, hoverSpring.Frequency, {
		Rotation = entry.DefaultRotation + (if highlighted then hoverSpring.Rotation else 0),
	})
	local scale = if entry.Pressed then multipliers.Hold elseif highlighted then multipliers.Hover else multipliers.Idle
	local base = entry.DefaultSize
	entry.Tween = TweenService:Create(button, tweenInfo, {
		Size = UDim2.new(base.X.Scale * scale, base.X.Offset * scale, base.Y.Scale * scale, base.Y.Offset * scale),
	})
	entry.Tween:Play()
end

local function release(button: GuiButton, entry)
	entry.Pressed = nil
	if entry.PressConnection then
		entry.PressConnection:Disconnect()
		entry.PressConnection = nil
	end
	updateAppearance(button, entry, releaseTweenInfo)
end

local function press(button: GuiButton, entry, input: InputObject)
	if entry.Pressed or not button.Active or not button.Interactable then
		return
	end
	entry.Pressed = input
	entry.PressConnection = input.Changed:Connect(function()
		if input.UserInputState == Enum.UserInputState.End or input.UserInputState == Enum.UserInputState.Cancel then
			release(button, entry)
		end
	end)
	updateAppearance(button, entry, pressTweenInfo)
end

local function tapEffect(button: GuiButton, input: InputObject)
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return
	end
	local position
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		position = UserInputService:GetMouseLocation()
	elseif input.UserInputType == Enum.UserInputType.Touch then
		-- Touch positions already subtract the GUI inset; the full-screen overlay does not.
		position = Vector2.new(input.Position.X, input.Position.Y) + GuiService:GetGuiInset()
	else
		-- AbsolutePosition is inset-relative; the effect uses screen coordinates.
		position = button.AbsolutePosition + button.AbsoluteSize / 2 + GuiService:GetGuiInset()
	end

	-- Keep the effect visible even when activation closes the button's panel.
	local screen = Instance.new("ScreenGui")
	screen.Name = "ButtonTapEffect"
	screen.IgnoreGuiInset = true
	screen.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
	screen.ResetOnSpawn = false
	local sourceGui = button:FindFirstAncestorWhichIsA("ScreenGui")
	screen.DisplayOrder = if sourceGui then sourceGui.DisplayOrder + 1 else 100
	screen.Parent = playerGui
	Debris:AddItem(screen, rippleTweenInfo.Time + 0.05)

	local ring = Instance.new("Frame")
	ring.Name = "Ring"
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position = UDim2.fromOffset(position.X, position.Y)
	ring.Size = UDim2.fromOffset(20, 20)
	ring.BackgroundColor3 = Color3.new(1, 1, 1)
	ring.BackgroundTransparency = 0.82
	ring.BorderSizePixel = 0
	ring.Active = false
	ring.Parent = screen
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = ring
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	stroke.Thickness = 2 / 10
	stroke.Transparency = 0.15
	stroke.Parent = ring
	local diameter = math.clamp(button.AbsoluteSize.Y * 0.85, 36, 68)
	-- Preserve the original 2px -> 0.5px taper as the scaled ring expands.
	ring:GetPropertyChangedSignal("Size"):Connect(function()
		local size = ring.Size.X.Offset
		local progress = math.clamp((size - 10) / (diameter - 10), 0, 1)
		stroke.Thickness = (2 - 1.5 * progress) / size
	end)
	TweenService:Create(ring, rippleTweenInfo, {
		Size = UDim2.fromOffset(diameter, diameter),
		BackgroundTransparency = 1,
	}):Play()
	TweenService:Create(stroke, rippleTweenInfo, { Transparency = 1 }):Play()
end

-->
local Animate = {
	ButtonConnections = {},
	ButtonStates = {},
}

-- Public Methods
function Animate:connect(button: GuiButton)
	if self.ButtonConnections[button] then
		return
	end
	local entry = {
		DefaultSize = getDefaultSize(button),
		DefaultRotation = button.Rotation,
		ImageColor = if button:IsA("ImageButton") then button.ImageColor3 else nil,
		Hovered = false,
		Selected = GuiService.SelectedObject == button,
	}
	self.ButtonStates[button] = entry
	local connections = {}
	self.ButtonConnections[button] = connections
	local function connect(signal, callback)
		table.insert(connections, signal:Connect(callback))
	end
	connect(button.MouseEnter, function()
		if UserInputService.PreferredInput ~= Enum.PreferredInput.KeyboardAndMouse then
			return
		end
		entry.Hovered = true
		updateAppearance(button, entry, hoverTweenInfo)
		playSound("Hover")
	end)
	connect(button.MouseLeave, function()
		entry.Hovered = false
		release(button, entry)
	end)
	connect(button.SelectionGained, function()
		entry.Selected = true
		updateAppearance(button, entry, hoverTweenInfo)
		playSound("Hover")
	end)
	connect(button.SelectionLost, function()
		entry.Selected = false
		release(button, entry)
	end)
	connect(button.InputBegan, function(input)
		if
			input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch
		then
			press(button, entry, input)
		end
	end)
	connect(UserInputService.InputBegan, function(input)
		if GuiService.SelectedObject == button and input.KeyCode == Enum.KeyCode.ButtonA then
			press(button, entry, input)
		end
	end)
	connect(UserInputService.InputEnded, function(input)
		if entry.Pressed == input then
			release(button, entry)
		end
	end)
	connect(UserInputService.WindowFocusReleased, function()
		entry.Hovered = false
		release(button, entry)
	end)
	connect(UserInputService:GetPropertyChangedSignal("PreferredInput"), function()
		entry.Hovered = false
		updateAppearance(button, entry, hoverTweenInfo)
	end)
	connect(button:GetPropertyChangedSignal("Visible"), function()
		if not button.Visible then
			entry.Hovered = false
			release(button, entry)
		end
	end)
	connect(button.Activated, function(input)
		release(button, entry)
		tapEffect(button, input)
		-- A button can swap the generic click for its own UI sound via a ClickSound attribute.
		local clickSound = button:GetAttribute("ClickSound")
		playSound(if typeof(clickSound) == "string" then clickSound else "Click")
	end)
	connect(button.Destroying, function()
		self:disconnect(button)
	end)
end

function Animate:disconnect(button: GuiButton)
	local connections = self.ButtonConnections[button]
	if not connections then
		return
	end
	for _, connection in connections do
		connection:Disconnect()
	end
	local entry = self.ButtonStates[button]
	if entry.PressConnection then
		entry.PressConnection:Disconnect()
	end
	if entry.Tween then
		entry.Tween:Cancel()
	end
	Spring.stop(button, "Rotation")
	if not button:HasTag("StaticBtn") then
		button.Size = entry.DefaultSize
		button.Rotation = entry.DefaultRotation
	end
	if entry.ImageColor then
		button.ImageColor3 = entry.ImageColor
	end
	self.ButtonConnections[button] = nil
	self.ButtonStates[button] = nil
end

return Animate
