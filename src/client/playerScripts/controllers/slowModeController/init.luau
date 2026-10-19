-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local Spring = require(ReplicatedStorage.src.utility.Spring)

-- Config
local colorTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local knobSpring = { Damping = 0.55, Frequency = 6 }
local styles = {
	[true] = {
		KnobX = 0.58,
		Knob = Color3.fromRGB(113, 247, 30),
		KnobOutline = Color3.fromRGB(23, 46, 15),
		Track = Color3.fromRGB(31, 55, 30),
	},
	[false] = {
		KnobX = 0.06,
		Knob = Color3.fromRGB(255, 63, 69),
		KnobOutline = Color3.fromRGB(70, 10, 14),
		Track = Color3.fromRGB(60, 22, 26),
	},
}

-->
-- The HUD's Slow Mode switch: while it's on, WalkSpeedService caps the player's WalkSpeed.
local SlowModeController = knit.CreateController({
	Name = "SlowModeController",
	IsEnabled = false,
	Changed = Signal.new(), -- (isEnabled: boolean)
})

-- Public Methods
function SlowModeController:Toggle()
	self:SetEnabled(not self.IsEnabled)
end

function SlowModeController:SetEnabled(isEnabled: boolean)
	if self.IsEnabled == isEnabled then
		return
	end

	self.IsEnabled = isEnabled
	self:render(true)
	self.WalkSpeedService:SetSlowMode(isEnabled):catch(warn)
	self.Changed:Fire(isEnabled)
end

-- Private Methods
function SlowModeController:render(animate: boolean)
	local track = self.Track
	if not track then
		return
	end

	local knob = track.Knob
	local style = styles[self.IsEnabled]
	local position = UDim2.new(style.KnobX, 0, knob.Position.Y.Scale, knob.Position.Y.Offset)

	if not animate then
		knob.Position = position
		knob.BackgroundColor3 = style.Knob
		knob.Outline.Color = style.KnobOutline
		track.BackgroundColor3 = style.Track
		return
	end

	Spring.target(knob, knobSpring.Damping, knobSpring.Frequency, { Position = position })
	TweenService:Create(knob, colorTweenInfo, { BackgroundColor3 = style.Knob }):Play()
	TweenService:Create(knob.Outline, colorTweenInfo, { Color = style.KnobOutline }):Play()
	TweenService:Create(track, colorTweenInfo, { BackgroundColor3 = style.Track }):Play()
end

-- LifeCycle
function SlowModeController:KnitInit()
	self.WalkSpeedService = knit.GetService("WalkSpeedService")
end

function SlowModeController:KnitStart()
	task.spawn(function()
		local hud = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Hud")
		self.Track = hud:WaitForChild("LeftMenu"):WaitForChild("SlowMode"):WaitForChild("Track")
		self:render(false)
	end)
end

return SlowModeController
