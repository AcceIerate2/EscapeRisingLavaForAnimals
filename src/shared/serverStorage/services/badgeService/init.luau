-- Roblox Services
local BadgeService = game:GetService("BadgeService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)

-->
local badgeService = knit.CreateService({
	Name = "BadgeService",
	Config = require(ReplicatedStorage.src.GameConfiguration.General.badgeConfig),
})

function badgeService:ownsBadge(player: Player, badgeId: number)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player")
	assert(TypeCheck.number(badgeId), "badgeId arg must be a number")

	local userId = player.UserId
	local status: boolean, response = SafeFunctionCaller(BadgeService.UserHasBadgeAsync, BadgeService, userId, badgeId)
	return status and response or false
end

function badgeService:awardBadge(player: Player, badgeId: number)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player")
	assert(TypeCheck.number(badgeId), "badgeId arg must be a number")

	if RunService:IsStudio() then
		return
	end

	local userId = player.UserId
	SafeFunctionCaller(BadgeService.AwardBadgeAsync, BadgeService, userId, badgeId)
end

function badgeService:awardWelcomeBadges(player: Player)
	assert(TypeCheck.Instance(player) and player:IsA("Player"), "player arg must be a Player")
	for _, badgeId: number in pairs(self.Config.WelcomeBadges) do
		self:awardBadge(player, badgeId)
	end
end

function badgeService:KnitInit() end

return badgeService
