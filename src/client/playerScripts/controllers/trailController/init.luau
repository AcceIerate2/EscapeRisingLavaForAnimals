-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Config
local trailsConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.trailsConfig)

-->
local TrailController = knit.CreateController({
	Name = "TrailController",
	Config = trailsConfig,
})

-- Public Methods
function TrailController:BuyWithCash(trailId: string)
	if not self.Config.GetTrail(trailId) then
		return
	end

	self.TrailService
		:BuyTrail(trailId)
		:andThen(function(response)
			self:handleResponse(response)
		end)
		:catch(warn)
end

function TrailController:BuyWithRobux(trailId: string)
	local trail = self.Config.GetTrail(trailId)
	if not trail or trail.ProductId == 0 then
		return
	end

	self.MonetizationController:promptPurchase("Product", trail.ProductId)
end

function TrailController:ToggleEquip(trailId: string)
	if not self.Config.GetTrail(trailId) then
		return
	end

	local promise = if self.DataController:GetValue("EquippedTrail") == trailId
		then self.TrailService:UnequipTrail()
		else self.TrailService:EquipTrail(trailId)

	promise
		:andThen(function(response)
			self:handleResponse(response)
		end)
		:catch(warn)
end

-- Private Methods
function TrailController:handleResponse(response)
	if not TypeCheck.table(response) or not TypeCheck.table(response.NotificationData) then
		return
	end

	self.NotificationController:Push(response.NotificationData)
end

-- LifeCycle
function TrailController:KnitInit()
	self.TrailService = knit.GetService("TrailService")
	self.DataController = knit.GetController("DataController")
	self.MonetizationController = knit.GetController("MonetizationController")
	self.NotificationController = knit.GetController("NotificationController")
end

return TrailController
