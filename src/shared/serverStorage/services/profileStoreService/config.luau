-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config
local settingsConfig = require(ReplicatedStorage.src.GameConfiguration.General.settingsConfig)

-->
return {
	DataTemplate = {
		Cash = 500000,
		Rebirths = 0,

		Speed = 0,
		MaxHold = 1,
		PlotLevel = 1,

		OwnedTrails = {},
		EquippedTrail = "",

		Settings = settingsConfig.GetDefaults(),

		LastSeen = 0,
		JoinedBefore = false,

		PurchaseHistory = {},
	},
}
