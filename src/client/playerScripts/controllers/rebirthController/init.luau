-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Config
local rebirthConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.rebirthConfig)
local fillTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Essentials
local player = Players.LocalPlayer

-- Helper Functions
local function formatMultiplier(multiplier: number): string
	return `x{math.round(multiplier * 100) / 100} Money`
end

-->
local RebirthController = knit.CreateController({
	Name = "RebirthController",
	Config = rebirthConfig,
})

-- Public Methods
function RebirthController:RequestRebirth()
	self.RebirthService
		:Rebirth()
		:andThen(function(response)
			self:notify(response)
		end)
		:catch(warn)
end

function RebirthController:RequestSkip()
	local productId = self.Config.SkipProductId
	if productId == 0 then
		self:notify({
			NotificationData = { Message = "Skip Rebirth is coming soon!", Color = Color3.new(1, 1, 1) },
		})
		return
	end
	self.MonetizationController:promptPurchase("Product", productId)
end

-- Private Methods
function RebirthController:notify(response)
	if TypeCheck.table(response) and TypeCheck.table(response.NotificationData) then
		self.NotificationController:Push(response.NotificationData)
	end
end

-- Display only; the server decides whether a rebirth is allowed.
function RebirthController:render()
	local content = self.Content
	if not content then
		return
	end

	local rebirths = self.DataController:GetValue("Rebirths") or 0
	local speed = self.DataController:GetValue("Speed") or 0
	local maxed = self.Config.IsMaxed(rebirths)
	local requirement = self.Config.GetRequirement(rebirths)

	content.Current.Tier.Text = `Rebirth {rebirths}`
	content.Current.Boost.Multiplier.Text = formatMultiplier(self.Config.GetMultiplier(rebirths))
	content.Next.Tier.Text = if maxed then "Max" else `Rebirth {rebirths + 1}`
	content.Next.Boost.Multiplier.Text = if maxed then "-" else formatMultiplier(self.Config.GetMultiplier(rebirths + 1))

	local progress = if maxed then 1 else math.clamp(speed / requirement, 0, 1)
	TweenService:Create(content.SpeedRequirement.Fill, fillTweenInfo, { Size = UDim2.fromScale(progress, 1) }):Play()
	content.SpeedRequirement.Value.Text = if maxed
		then "Max Rebirth!"
		else `{NumberShortner(math.floor(speed))} / {NumberShortner(requirement)} Speed`
end

function RebirthController:bindPanel()
	local panel = player:WaitForChild("PlayerGui"):WaitForChild("Panels"):WaitForChild("Rebirth")
	self.Content = panel:WaitForChild("Content")

	-- Wire the panel buttons into the shared button system (animations, sounds, Action handlers).
	local actions = self.Content:WaitForChild("Actions")
	local wiring = {
		{ actions:WaitForChild("Rebirth"), { Type = "Action", Action = "Rebirth" } },
		{ actions:WaitForChild("SkipRebirth"), { Type = "Action", Action = "SkipRebirth" } },
		{ panel:WaitForChild("Header"):WaitForChild("Close"), { Type = "PanelToggler", PanelName = "Rebirth" } },
	}
	for _, entry in wiring do
		local button, attributes = entry[1], entry[2]
		for name, value in attributes do
			button:SetAttribute(name, value)
		end
		self.ButtonsController:Link(button)
	end

	self:render()
	self.DataController:GetValueChangedSignal("Rebirths"):Connect(function()
		self:render()
	end)
	self.DataController:GetValueChangedSignal("Speed"):Connect(function()
		self:render()
	end)
end

-- LifeCycle
function RebirthController:KnitInit()
	self.RebirthService = knit.GetService("RebirthService")
	self.DataController = knit.GetController("DataController")
	self.ButtonsController = knit.GetController("ButtonsController")
	self.NotificationController = knit.GetController("NotificationController")
	self.MonetizationController = knit.GetController("MonetizationController")
end

function RebirthController:KnitStart()
	task.spawn(function()
		-- The shared button system is listening once the UI has initialised.
		player:WaitForChild("ClientReady")
		self:bindPanel()
	end)
end

return RebirthController
