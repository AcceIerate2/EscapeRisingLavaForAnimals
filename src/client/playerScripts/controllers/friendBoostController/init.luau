-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local friendBoostConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.friendBoostConfig)

-- Essentials
local player = Players.LocalPlayer

-->
-- Shows the local player's friend boost (from FriendBoostService) on Hud.Counters.FriendBoost.
local FriendBoostController = knit.CreateController({
	Name = "FriendBoostController",
})

-- Private Methods
function FriendBoostController:render(animate: boolean)
	local boost = player:GetAttribute("FriendBoost") or 0
	local percent = math.round(boost * 100)
	self.Label.Text = `Friend Boost: <font color="{friendBoostConfig.Color}">+{percent}%</font>`

	if animate then
		self.Scale.Scale = 1.15
		TweenService:Create(self.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end
end

-- LifeCycle
function FriendBoostController:KnitStart()
	task.spawn(function()
		local frame = player:WaitForChild("PlayerGui"):WaitForChild("Hud"):WaitForChild("Counters"):WaitForChild("FriendBoost")
		self.Label = frame:WaitForChild("Label")
		-- On the frame, not the label: the label's text size cap would stop its text from growing.
		self.Scale = Instance.new("UIScale")
		self.Scale.Parent = frame

		self:render(false)
		player:GetAttributeChangedSignal("FriendBoost"):Connect(function()
			self:render(true)
		end)
	end)
end

return FriendBoostController
