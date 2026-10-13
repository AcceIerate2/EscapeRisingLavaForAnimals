-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)

-- Config
local shineTweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, false, 2.2)
local pulseTweenInfo = TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
local pulseScale = 1.05
local staggerSeconds = 0.35

-->
local ShopTitles = {}

-- Private Methods
function ShopTitles:animate(title: TextLabel, delaySeconds: number)
	local shine = title:FindFirstChild("Shine")
	local pulse = title:FindFirstChild("Pulse")

	task.delay(delaySeconds, function()
		-- The white band in Shine sweeps from off the left edge to off the right edge.
		if shine and shine:IsA("UIGradient") then
			shine.Offset = Vector2.new(-1, 0)
			TweenService:Create(shine, shineTweenInfo, { Offset = Vector2.new(1, 0) }):Play()
		end

		if pulse and pulse:IsA("UIScale") then
			TweenService:Create(pulse, pulseTweenInfo, { Scale = pulseScale }):Play()
		end
	end)
end

-- LifeCycle
function ShopTitles:Init(_player: Player)
	local offers = utility.getPanel("Shop"):WaitForChild("Offers")

	-- Each Title is a fixed-size holder in the list layout, so pulsing its Label never shifts other rows.
	local holders = {}
	for _, child in offers:GetChildren() do
		local label = child.Name == "Title" and child:FindFirstChild("Label")
		if label and label:IsA("TextLabel") and label:FindFirstChild("Shine") then
			table.insert(holders, child)
		end
	end

	-- Top to bottom, so the shine ripples down the shop instead of flashing all at once.
	table.sort(holders, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)

	for index, holder in holders do
		self:animate(holder.Label, (index - 1) * staggerSeconds)
	end
end

return ShopTitles
