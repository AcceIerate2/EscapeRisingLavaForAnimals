-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local attributeName = "InSafeZone" -- set by SafeZoneService
local showTweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local hideTweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-->
-- Shows the "In Safezone" label while the server says the player is in a safe zone.
local SafeZoneController = knit.CreateController({
	Name = "SafeZoneController",
	IsInSafeZone = false,
	Changed = Signal.new(), -- (isInSafeZone: boolean)
})

-- Private Methods
function SafeZoneController:render(isInSafeZone: boolean)
	local label = self.Label
	if not label then
		return
	end

	if self.Tween then
		self.Tween:Cancel()
	end

	if isInSafeZone then
		label.Visible = true
		label.Pop.Scale = 0.6
		self.Tween = TweenService:Create(label.Pop, showTweenInfo, { Scale = 1 })
	else
		self.Tween = TweenService:Create(label.Pop, hideTweenInfo, { Scale = 0 })
		self.Tween.Completed:Connect(function(playbackState)
			if playbackState == Enum.PlaybackState.Completed then
				label.Visible = false
			end
		end)
	end
	self.Tween:Play()
end

function SafeZoneController:update()
	local isInSafeZone = Players.LocalPlayer:GetAttribute(attributeName) == true
	if isInSafeZone == self.IsInSafeZone then
		return
	end

	self.IsInSafeZone = isInSafeZone
	self:render(isInSafeZone)
	self.Changed:Fire(isInSafeZone)
end

-- LifeCycle
function SafeZoneController:KnitStart()
	task.spawn(function()
		self.Label = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Hud"):WaitForChild("SafeZoneStatus")
		self.Label.Visible = false

		Players.LocalPlayer:GetAttributeChangedSignal(attributeName):Connect(function()
			self:update()
		end)
		self:update()
	end)
end

return SafeZoneController
