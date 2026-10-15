-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local settingsConfig = require(ReplicatedStorage.src.GameConfiguration.General.settingsConfig)

-->
local SettingsService = knit.CreateService({
	Name = "SettingsService",
	Client = {},
	Config = settingsConfig,
})

-- Client Exposed Methods
function SettingsService.Client:SetSetting(player: Player, key: string, value: any)
	return self.Server:SetSetting(player, key, value)
end

function SettingsService.Client:ResetSettings(player: Player)
	return self.Server:ResetSettings(player)
end

-- Public Methods
function SettingsService:ResetSettings(player: Player): boolean
	local valueObject = self.DataService:GetValueObject(player, "Settings")
	if not valueObject then
		return false
	end
	valueObject:Set(self.Config.GetDefaults())
	return true
end

function SettingsService:SetSetting(player: Player, key: string, value: any): boolean
	local setting = typeof(key) == "string" and self.Config.Settings[key]
	if not setting then
		return false
	end

	if setting.Type == "Volume" then
		if typeof(value) ~= "number" or value ~= value then
			return false
		end
		value = math.round(math.clamp(value, 0, 1) * 100) / 100
	elseif setting.Type == "Toggle" then
		if typeof(value) ~= "boolean" then
			return false
		end
	end

	local valueObject = self.DataService:GetValueObject(player, "Settings")
	if not valueObject then
		return false
	end
	valueObject:Update(function(settings)
		settings[key] = value
	end)
	return true
end

-- LifeCycle
function SettingsService:KnitInit()
	self.DataService = knit.GetService("DataService")
end

return SettingsService
