-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local friendBoostConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.friendBoostConfig)

-->
-- Counts each player's Roblox friends in the server and publishes their boost on the player as the
-- "FriendBoost" attribute (0.1 = +10%) for the HUD. The cash income system should multiply its
-- earnings by GetMultiplier(player) once it exists.
local FriendBoostService = knit.CreateService({
	Name = "FriendBoostService",
	Client = {},
	Config = friendBoostConfig,
	Friends = {}, -- [player] = { [friend player] = true }
})

-- Public Methods
function FriendBoostService:GetBoost(player: Player): number
	return player:GetAttribute("FriendBoost") or 0
end

-- What cash income should be multiplied by: 1 + the boost (e.g. 1.3 with three friends here).
function FriendBoostService:GetMultiplier(player: Player): number
	return 1 + self:GetBoost(player)
end

-- Private Methods
function FriendBoostService:update(player: Player)
	local friends = self.Friends[player]
	local count = 0
	for _ in friends or {} do
		count += 1
	end
	if player.Parent == Players then
		player:SetAttribute("FriendBoost", friendBoostConfig.GetBoost(count))
	end
end

-- Friendship goes both ways, so one check per pair updates both players.
function FriendBoostService:addPlayer(player: Player)
	self.Friends[player] = self.Friends[player] or {}
	self:update(player)

	for _, other in Players:GetPlayers() do
		if other == player then
			continue
		end
		local ok, isFriend = pcall(player.IsFriendsWith, player, other.UserId)
		if ok and isFriend and self.Friends[player] and self.Friends[other] then
			self.Friends[player][other] = true
			self.Friends[other][player] = true
			self:update(other)
		end
	end
	self:update(player)
end

function FriendBoostService:removePlayer(player: Player)
	self.Friends[player] = nil
	for other, friends in self.Friends do
		if friends[player] then
			friends[player] = nil
			self:update(other)
		end
	end
end

-- LifeCycle
function FriendBoostService:KnitStart()
	Players.PlayerAdded:Connect(function(player: Player)
		self:addPlayer(player)
	end)
	Players.PlayerRemoving:Connect(function(player: Player)
		self:removePlayer(player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(self.addPlayer, self, player)
	end
end

return FriendBoostService
