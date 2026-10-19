-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config
local rebirthConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.rebirthConfig)

-- Helper Functions
local function notify(message: string, success: boolean)
	local sounds = SoundService.src.Sfx.NotificationSounds
	return {
		Status = success,
		NotificationData = {
			Message = message,
			Color = if success then Color3.new(1, 1, 1) else Color3.fromRGB(255, 0, 0),
			Sound = if success then sounds.Accept else sounds.Decline,
		},
	}
end

-->
local RebirthService = knit.CreateService({
	Name = "RebirthService",
	Client = {
		Rebirthed = knit.CreateSignal(), -- (rebirths: number) for client celebration effects
	},
	Config = rebirthConfig,
	LastRequest = {},
})

-- Client Exposed Methods
-- The client only asks; every check and change happens here on the server.
function RebirthService.Client:Rebirth(player: Player)
	return self.Server:Rebirth(player)
end

-- Public Methods
function RebirthService:GetRebirths(player: Player): number
	local rebirths = self.DataService:GetValue(player, "Rebirths")
	return if typeof(rebirths) == "number" then rebirths else 0
end

-- For income systems to multiply money by.
function RebirthService:GetCashMultiplier(player: Player): number
	return self.Config.GetMultiplier(self:GetRebirths(player))
end

function RebirthService:Rebirth(player: Player)
	if not self.DataService:GetProfile(player) then
		return { Status = false }
	end

	local now = os.clock()
	if now - (self.LastRequest[player] or 0) < self.Config.RequestCooldown then
		return { Status = false }
	end
	self.LastRequest[player] = now

	local rebirths = self:GetRebirths(player)
	if self.Config.IsMaxed(rebirths) then
		return notify("You've reached the max rebirth!", false)
	end

	local requirement = self.Config.GetRequirement(rebirths)
	local speed = self.DataService:GetValue(player, "Speed") or 0
	if speed < requirement then
		return notify(`You need {NumberShortner(requirement - speed)} more Speed to rebirth!`, false)
	end

	self:grantRebirth(player, false)
	return notify(
		`Rebirthed! You now earn <font color="rgb(89,255,31)">x{self:GetCashMultiplier(player)}</font> money.`,
		true
	)
end

-- Private Methods
function RebirthService:grantRebirth(player: Player, keepSpeed: boolean)
	local rebirths = self:GetRebirths(player) + 1

	for dataKey, resetTo in self.Config.Reset do
		if keepSpeed and dataKey == "Speed" then
			continue
		end

		if dataKey == "Cash" then
			local cash = self.DataService:GetValue(player, "Cash") or 0
			self.CashService:ManipulatePlayerCash(player, resetTo - cash, "Addition")
		else
			self.DataService:GetValueObject(player, dataKey):Set(resetTo)
		end
	end

	self.DataService:GetValueObject(player, "Rebirths"):Set(rebirths)
	self.Client.Rebirthed:Fire(player, rebirths)
end

function RebirthService:registerSkipProduct()
	local productId = self.Config.SkipProductId
	if productId == 0 then
		return
	end

	-- Granted only through the verified purchase receipt.
	self.MonetizationService.ProductIds[productId] = function(player: Player)
		if self.Config.IsMaxed(self:GetRebirths(player)) then
			error("Player is at max rebirth") -- leaves the receipt unprocessed instead of wasting it
		end
		self:grantRebirth(player, true)
		return true
	end
end

-- LifeCycle
function RebirthService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.MonetizationService = knit.GetService("MonetizationService")
	self:registerSkipProduct()

	Players.PlayerRemoving:Connect(function(player: Player)
		self.LastRequest[player] = nil
	end)
end

return RebirthService
