-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local GiftService = knit.CreateService({
	Name = "GiftService",
	Client = { GiftRequest = knit.CreateSignal() },
	Queue = {},
})

function GiftService.Client:newGiftRequest(player, otherPlayerUserId, productId, purchaseType)
	return self.Server:newGiftRequest(player, otherPlayerUserId, productId, purchaseType)
end

function GiftService:newGiftRequest(player: Player, otherPlayerUserId: number, productId: number, purchaseType: string)
	assert(TypeCheck.Instance(player), "player arg must be a Player")
	assert(TypeCheck.number(otherPlayerUserId), "otherPlayerUserId arg must be a number")
	assert(TypeCheck.number(productId), "productId arg must be a number")
	assert(TypeCheck.string(purchaseType), "purchaseType arg must be a string")

	local otherPlayer = Players:GetPlayerByUserId(otherPlayerUserId)
	if not otherPlayer then
		return {
			Status = false,
			NotificationData = {
				Message = "Player Left.",
				Color = Color3.fromRGB(255, 0, 0),
				Sound = SoundService.Sfx.NotificationSounds.Decline,
			},
		}
	end

	local exists = self.Queue[player]
	if TypeCheck.table(exists) then
		if exists.Id == productId and exists.PurchaseType == purchaseType and exists.OtherPlayer == otherPlayer then
			return { Status = true } -- same request, ignore duplicate click
		end

		return {
			Status = false,
			NotificationData = {
				Message = "You already have a pending gift. Finish or cancel it first.",
				Color = Color3.fromRGB(255, 170, 0),
				Sound = SoundService.Sfx.NotificationSounds.Decline,
			},
		}
	end

	self.Queue[player] = {
		Id = productId,
		PurchaseType = purchaseType,
		OtherPlayer = otherPlayer,
	}

	return { Status = true }
end

function GiftService:popGiftRequest(player: Player)
	local data = self.Queue[player]
	self.Queue[player] = nil
	return data
end

function GiftService:peekGiftRequest(player: Player)
	return self.Queue[player]
end

function GiftService:clearGiftRequest(player: Player)
	self.Queue[player] = nil
end

function GiftService:KnitInit()
	Players.PlayerRemoving:Connect(function(player)
		self.Queue[player] = nil
	end)
end

return GiftService
