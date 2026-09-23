-- Roblox Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-->
local HapticController = knit.CreateController({
	Name = "HapticController",
})

-- Public Methods
function HapticController:Shake(hapticEffectType: Enum.HapticEffectType)
	local hapticEffect = InstanceCreator("HapticEffect", "HapticEffect", workspace, {
		Type = hapticEffectType or Enum.HapticEffectType.GameplayCollision,
	}) :: HapticEffect

	-- Doesn't work...
	--[[hapticEffect.Ended:Once(function()
		task.defer(hapticEffect.Destroy, hapticEffect)
	end)]]

	hapticEffect:Play()
	Debris:AddItem(hapticEffect, 3) -- Temp
end

function HapticController:KnitInit() end

return HapticController
