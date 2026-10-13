-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local functions = {
	OpenAnimals = function()
		knit.GetController("SideFrameController"):Open("Animals")
	end,

	OpenEggs = function()
		knit.GetController("SideFrameController"):Open("Eggs")
	end,

	CloseSideFrame = function()
		knit.GetController("SideFrameController"):Close()
	end,

	BuyTrailCash = function(button)
		knit.GetController("TrailController"):BuyWithCash(button:GetAttribute("TrailId"))
	end,

	BuyTrailRobux = function(button)
		knit.GetController("TrailController"):BuyWithRobux(button:GetAttribute("TrailId"))
	end,

	ToggleTrail = function(button)
		knit.GetController("TrailController"):ToggleEquip(button:GetAttribute("TrailId"))
	end,

	ToggleSlowMode = function()
		knit.GetController("SlowModeController"):Toggle()
	end,

	UpgradePlot = function()
		knit.GetController("PlotController"):RequestUpgrade()
	end,

	OpenShopSection = function(button)
		knit.GetController("ShopController"):OpenSection(button:GetAttribute("ShopSection"))
	end,
}

return function(button)
	if not button then
		return
	end

	local actionType = TypeCheck.Instance(button) and button:GetAttribute("Action") or button
	if not TypeCheck.string(actionType) then
		return
	end

	local functionToCall = functions[actionType]
	if typeof(functionToCall) ~= "function" then
		return
	end

	functionToCall(button)
end
