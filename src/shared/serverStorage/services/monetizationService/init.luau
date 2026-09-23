-- Roblox Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)

-->
local MonetizationService = knit.CreateService({
	Name = "MonetizationService",
	Client = {
		UserPurchased = knit.CreateSignal(),
	},

	ProductIds = require(script.productIds),
	PassIds = require(script.passIds),
})

function MonetizationService.Client:getMonetizationItemInfo(
	_player: Player,
	monetizationType: "Product" | "GamePass",
	id: number
)
	return self.Server:getMonetizationItemInfo(monetizationType, id)
end

function MonetizationService:getMonetizationItemInfo(
	monetizationType: "Product" | "GamePass",
	id: number
): { [string]: any }
	assert(TypeCheck.string(monetizationType), "monetizationType arg must be a string")
	assert(TypeCheck.number(id), "id arg must be a number")

	if monetizationType:lower() == "gamepass" then
		monetizationType = "GamePass"
	end

	local status: boolean, response: { [string]: any } = SafeFunctionCaller(
		MarketplaceService.GetProductInfoAsync,
		MarketplaceService,
		id,
		Enum.InfoType[monetizationType]
	)

	return status and response or {}
end

function MonetizationService:gamepassPurchaseHandler(player: Player, passId: number, init: boolean)
	assert(TypeCheck.Instance(player), "player arg must be a Player")
	assert(TypeCheck.number(passId), "passId arg must be a number")

	local grantPurchaseHandler = self.PassIds[passId]
	if not grantPurchaseHandler then
		return
	end

	if init == nil then
		init = false
	end

	grantPurchaseHandler(player, init)
end

function MonetizationService:loadGamepasses(player: Player)
	local userId = player.UserId

	for passId: number in pairs(self.PassIds) do
		local status, owns =
			SafeFunctionCaller(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, userId, passId)

		if not status or not owns then
			continue
		end

		self:gamepassPurchaseHandler(player, passId, true)
	end
end

function MonetizationService:productPurchaseHandler(player: Player, productId: number) -- Exposed Method for other services to call
	local grantPurchaseHandler = self.ProductIds[productId]
	if typeof(grantPurchaseHandler) ~= "function" then
		return
	end
	SafeFunctionCaller(grantPurchaseHandler, player)
end

function MonetizationService:processReceipt(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseHistoryValueObject = self.DataService:get(player, "PurchaseHistory")
	local history = purchaseHistoryValueObject:Get() or {}

	local purchaseKey = receiptInfo.PurchaseId
	if history[purchaseKey] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local grantPurchaseHandler = self.ProductIds[receiptInfo.ProductId]
	if not grantPurchaseHandler then
		warn(`No purchase handler defined for product ID {receiptInfo.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local gift = self.GiftService:peekGiftRequest(player)
	if gift then
		self.GiftService:clearGiftRequest(player)
		player = gift.OtherPlayer
	end

	local handlerSucceeded, handlerResult = SafeFunctionCaller(grantPurchaseHandler, player)
	if not handlerSucceeded then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local saved =
		pcall(purchaseHistoryValueObject.Insert, purchaseHistoryValueObject, purchaseKey, handlerResult or true)
	if not saved then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	self.Client.UserPurchased:Fire(player)
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

function MonetizationService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.GiftService = knit.GetService("GiftService")

	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:processReceipt(receiptInfo)
	end

	MarketplaceService.PromptProductPurchaseFinished:Connect(
		function(userId: number, productId: number, purchased: boolean)
			if purchased then
				return
			end

			local player = Players:GetPlayerByUserId(userId)
			if not player then
				return
			end

			self.GiftService:clearGiftRequest(player)
		end
	)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player: Player, passId: number, purchased: boolean)
			local gift = self.GiftService:peekGiftRequest(player)
			if gift then
				self.GiftService:clearGiftRequest(player)
				if purchased then
					local other = gift.OtherPlayer
					if other then
						player = other
					end
				end
			end

			if not purchased then
				return
			end

			self.Client.UserPurchased:Fire(player)
			self:gamepassPurchaseHandler(player, passId, false)
		end
	)
end

return MonetizationService
