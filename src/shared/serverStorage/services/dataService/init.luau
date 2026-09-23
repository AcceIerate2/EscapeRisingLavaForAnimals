-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
-->
local DataService = knit.CreateService({
	Name = "DataService",

	Client = {
		ValueObjectChanged = knit.CreateSignal(),
	},
	Data = {},

	ValueObjectModule = require(script.ValueObject),
	LeaderstatsHandler = require(script.leaderstats),
})

-- Client Exposed Methods
function DataService.Client:GetProfileKeys(player: Player)
	local dataToReturn: { string } = {}

	local profile = self.Server:GetProfile(player)
	for key: string, _ in pairs(profile) do
		table.insert(dataToReturn, key)
	end
	return dataToReturn
end

function DataService.Client:GetValue(player: Player, valueName: string): any
	return self.Server:GetValue(player, valueName)
end

-- Public Methods
function DataService:GetValue(player: Player, valueName: string): any
	assert(typeof(player) == "Instance", "player arg must be a player")
	local playerData = self:GetProfile(player)
	return playerData and playerData[valueName]:Get()
end

function DataService:GetValueObject(player: Player, valueName: string)
	assert(typeof(player) == "Instance", "player arg must be a player")
	local playerData = self:GetProfile(player)
	return playerData[valueName]
end

function DataService:GetProfile(player: Player)
	assert(typeof(player) == "Instance", "player arg must be a player")
	return self.Data[player]
end

function DataService:Delete(player: Player, valueName: string)
	assert(typeof(player) == "Instance", "player arg must be a player")
	local playerData = self:GetProfile(player)
	playerData[valueName]:Destroy()
	playerData[valueName] = nil
end

function DataService:Create(player: Player, profileData, valueData: { Name: string, Value: any })
	local playerData = self:GetProfile(player)

	local name = valueData.Name
	local value = valueData.Value

	local valueExists = playerData[name] ~= nil
	assert(valueExists == false, "Attempt to connect existing Value to player data")

	playerData[name] = self.ValueObjectModule:Create(
		name,
		value,
		profileData,
		function(key: string, newValue: any?, customData: { Key: string, NewValue: any? }?)
			self.Client.ValueObjectChanged:Fire(player, key, newValue, customData)
		end
	)
	return playerData[name]
end

function DataService:ConnectProfile(player: Player, profileData)
	self.Data[player] = {}

	for valueName: string, value: any in pairs(profileData) do
		local valueData = {
			Name = valueName,
			Value = value,
		}
		self:Create(player, profileData, valueData)
	end

	self.LeaderstatsHandler:Setup(player, self:GetProfile(player))
end

function DataService:DisconnectProfile(player: Player)
	self.LeaderstatsHandler:Clear(player, self:GetProfile(player))
	local profile = self:GetProfile(player)

	for _, data in pairs(profile or {}) do
		data:Destroy()
	end

	self.Data[player] = nil
end

return DataService
