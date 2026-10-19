local FriendBoostConfig = {}

--[[
	Playing in the same server as Roblox friends boosts your cash income.
	Boost = PerFriend * friends in the server, capped at Max (0.1 = +10%).
	Cash income multiplier = 1 + Boost (FriendBoostService:GetMultiplier).
]]
FriendBoostConfig.PerFriend = 0.1
FriendBoostConfig.Max = 0.5

FriendBoostConfig.Color = "#59FF1F" -- colour of the "+X%" on the HUD label

function FriendBoostConfig.GetBoost(friends: number): number
	return math.min(friends * FriendBoostConfig.PerFriend, FriendBoostConfig.Max)
end

return FriendBoostConfig
