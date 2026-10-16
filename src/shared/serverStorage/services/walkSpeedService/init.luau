-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local walkSpeedConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.walkSpeedConfig)

-->
-- Sets each player's Humanoid.WalkSpeed from their Speed stat (through walkSpeedConfig's curve), and
-- keeps it updated as Speed changes (treadmill, rebirths, rewards...).
local WalkSpeedService = knit.CreateService({
	Name = "WalkSpeedService",
	Client = {},
	Config = walkSpeedConfig,
	Connections = {}, -- [player] = RBXScriptConnection on their Speed value
})

-- Public Methods
function WalkSpeedService:GetWalkSpeed(player: Player): number
	local speed = self.DataService:GetValue(player, "Speed") or 0
	return walkSpeedConfig.ToWalkSpeed(speed)
end

function WalkSpeedService:Refresh(player: Player)
	if not self.DataService:GetProfile(player) then
		return
	end
	self:watch(player)

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = self:GetWalkSpeed(player)
	end
end

-- Private Methods
function WalkSpeedService:watch(player: Player)
	if self.Connections[player] then
		return
	end
	self.Connections[player] = self.DataService:GetValueObject(player, "Speed").Changed:Connect(function()
		self:Refresh(player)
	end)
end

-- LifeCycle
function WalkSpeedService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.PlayerService = knit.GetService("PlayerService")
end

function WalkSpeedService:KnitStart()
	self.PlayerService.CharacterAdded:Connect(function(player: Player, character: Model)
		character:WaitForChild("Humanoid", 10)
		self:Refresh(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		local connection = self.Connections[player]
		self.Connections[player] = nil
		if connection then
			connection:Disconnect()
		end
	end)
end

return WalkSpeedService
