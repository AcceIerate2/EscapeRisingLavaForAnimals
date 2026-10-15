-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

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

	InviteFriends = function()
		local player = Players.LocalPlayer
		local canInvite, result = pcall(SocialService.CanSendGameInviteAsync, SocialService, player)
		if canInvite and result then
			SocialService:PromptGameInvite(player)
		end
	end,

	ToggleSlowMode = function()
		knit.GetController("SlowModeController"):Toggle()
	end,

	ResetSettings = function()
		knit.GetController("SettingsController"):ResetToDefaults()
	end,

	Rebirth = function()
		knit.GetController("RebirthController"):RequestRebirth()
	end,

	SkipRebirth = function()
		knit.GetController("RebirthController"):RequestSkip()
	end,

	UpgradePlot = function()
		knit.GetController("PlotController"):RequestUpgrade()
	end,

	OpenShopSection = function(button)
		knit.GetController("ShopController"):OpenSection(button:GetAttribute("ShopSection"))
	end,

	LavaMachine = function()
		knit.GetController("LavaHudController"):RequestAction("LavaMachine")
	end,

	StopLava = function()
		knit.GetController("LavaHudController"):RequestAction("StopLava")
	end,

	SlowLava = function()
		knit.GetController("LavaHudController"):RequestAction("SlowLava")
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
