-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config
local settingsConfig = require(ReplicatedStorage.src.GameConfiguration.General.settingsConfig)

-->
return {
	DataTemplate = {
		Cash = 999_999_999_999,
		Rebirths = 0,

		Speed = 0,
		MaxHold = 1,
		PlotLevel = 1,
		TreadmillLevel = 0,

		OwnedTrails = {},
		EquippedTrail = "",

		Settings = settingsConfig.GetDefaults(),

		LastSeen = 0,
		JoinedBefore = false,

		PurchaseHistory = {},
	},
}
