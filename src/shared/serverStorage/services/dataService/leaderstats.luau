-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility Modules
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-->
local Leaderstats = {
	PlayerConnections = {},
	Config = require(ReplicatedStorage.src.GameConfiguration.Gameplay.leaderstatsConfig),
}

function Leaderstats:Setup(player: Player, playerData)
	local leaderstatsFolder = InstanceCreator("Folder", "leaderstats", player)

	self.PlayerConnections[player] = {}
	local playerConnectionsFolder = self.PlayerConnections[player]

	for _, valueName: string in pairs(self.Config.ValuesToDisplay) do
		local leaderstatsValueInstance: NumberValue =
			InstanceCreator("NumberValue", valueName, leaderstatsFolder) :: NumberValue

		local objectValue = playerData[valueName]
		leaderstatsValueInstance.Value = objectValue:Get()

		playerConnectionsFolder[valueName] = objectValue.Changed:Connect(function(newValue)
			leaderstatsValueInstance.Value = newValue
		end) :: RBXScriptConnection
	end
end

function Leaderstats:Clear(player: Player)
	local connections = self.PlayerConnections[player] or {}
	for _, connection: RBXScriptConnection in pairs(connections) do
		connection:Disconnect()
	end
	self.PlayerConnections[player] = nil
end

return Leaderstats
