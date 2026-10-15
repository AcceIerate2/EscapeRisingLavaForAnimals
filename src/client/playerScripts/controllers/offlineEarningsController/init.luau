-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config
local fadeTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local checkInterval = 0.2
local amountAttribute = "OfflinePerDay" -- set on the player by the server once offline income exists

-- Essentials
local player = Players.LocalPlayer

-->
local OfflineEarningsController = knit.CreateController({
	Name = "OfflineEarningsController",
	Shown = false,
})

-- Private Methods
-- World X/Z footprint of the fence parts, cached per fence model (a new one appears on upgrades).
function OfflineEarningsController:getFootprint(fences: Model)
	if self.FootprintFences == fences then
		return self.Footprint
	end

	local min, max = Vector3.one * math.huge, -Vector3.one * math.huge
	for _, part in fences:GetDescendants() do
		if part:IsA("BasePart") then
			local half = part.Size / 2
			for _, corner in
				{ Vector3.new(1, 1, 1), Vector3.new(-1, 1, 1), Vector3.new(1, 1, -1), Vector3.new(-1, 1, -1) }
			do
				local point = part.CFrame:PointToWorldSpace(half * corner)
				min, max = min:Min(point), max:Max(point)
			end
		end
	end

	self.FootprintFences = fences
	self.Footprint = { Min = min, Max = max }
	return self.Footprint
end

-- Inside the current fence's footprint (X/Z only).
function OfflineEarningsController:isInPlot(): boolean
	local plot = self.PlotController:GetPlot()
	local fences = plot and plot:FindFirstChild("Fences")
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if not fences or not root then
		return false
	end

	local footprint = self:getFootprint(fences)
	local position = root.Position
	return position.X >= footprint.Min.X
		and position.X <= footprint.Max.X
		and position.Z >= footprint.Min.Z
		and position.Z <= footprint.Max.Z
end

function OfflineEarningsController:updateText()
	local perDay = player:GetAttribute(amountAttribute)
	local amount = NumberShortner(math.floor(if typeof(perDay) == "number" then perDay else 0))
	self.Label.Text = `You earn <font color="#59FF1F">${amount}</font>/Day offline! 😈`
end

function OfflineEarningsController:setShown(shown: boolean)
	if self.Shown == shown then
		return
	end
	self.Shown = shown

	local transparency = if shown then 0 else 1
	TweenService:Create(self.Label, fadeTweenInfo, { TextTransparency = transparency }):Play()
	for _, child in self.Label:GetChildren() do
		if child:IsA("UIStroke") then
			TweenService:Create(child, fadeTweenInfo, { Transparency = transparency }):Play()
		end
	end
end

-- LifeCycle
function OfflineEarningsController:KnitInit()
	self.PlotController = knit.GetController("PlotController")
end

function OfflineEarningsController:KnitStart()
	task.spawn(function()
		self.Label = player:WaitForChild("PlayerGui"):WaitForChild("Hud"):WaitForChild("OfflineEarnings")

		-- Start hidden; it fades in the first time the player is inside their fences.
		self.Label.TextTransparency = 1
		for _, child in self.Label:GetChildren() do
			if child:IsA("UIStroke") then
				child.Transparency = 1
			end
		end

		self:updateText()
		player:GetAttributeChangedSignal(amountAttribute):Connect(function()
			self:updateText()
		end)

		while true do
			self:setShown(self:isInPlot())
			task.wait(checkInterval)
		end
	end)
end

return OfflineEarningsController
