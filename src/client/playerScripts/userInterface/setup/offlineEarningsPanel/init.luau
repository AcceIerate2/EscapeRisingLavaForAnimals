-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)

-- Config
local raysSpinTime = 8 -- seconds per full turn
local shineTweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 1.6)
local pulseTweenInfo = TweenInfo.new(0.7, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)

-->
local OfflineEarningsPanel = {}

-- Private Methods
local function loop(instance: Instance?, tweenInfo: TweenInfo, goal)
	if instance then
		TweenService:Create(instance, tweenInfo, goal):Play()
	end
end

-- LifeCycle
-- Everything loops on its own; it only costs anything while the panel is on screen.
function OfflineEarningsPanel:Init(_player: Player)
	local panel = utility.getPanel("OfflineEarnings")
	if not panel then
		return
	end

	local reward = panel:WaitForChild("Reward")
	local amount = reward:WaitForChild("Amount")
	local double = panel:WaitForChild("Double")

	-- Gold rays slowly spinning behind the cash icon.
	loop(reward:FindFirstChild("Rays"), TweenInfo.new(raysSpinTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), {
		Rotation = 360,
	})

	-- Shine bands sweeping across the amount and the title, slightly out of step.
	loop(amount:FindFirstChild("Shine"), shineTweenInfo, { Offset = Vector2.new(1, 0) })
	task.delay(0.45, loop, panel.Header.Title:FindFirstChild("Shine"), shineTweenInfo, { Offset = Vector2.new(1, 0) })

	-- The amount and the Double it! button breathe; the button's glow ring pulses with it.
	loop(amount:FindFirstChild("Pulse"), pulseTweenInfo, { Scale = 1.06 })
	loop(double:FindFirstChild("Pulse"), pulseTweenInfo, { Scale = 1.07 })
	loop(double:FindFirstChild("Glow"), pulseTweenInfo, { Transparency = 0.1 })
end

return OfflineEarningsPanel
