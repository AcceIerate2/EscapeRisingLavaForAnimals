-- Roblox Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Sfx
local MonetizationSounds =
	SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("MonetizationSounds") :: Folder
local promptSfx = MonetizationSounds:WaitForChild("Prompt") :: Sound
local purchaseSfx = MonetizationSounds:WaitForChild("PurchaseSuccess") :: Sound

-->
local MonetizationController = knit.CreateController({
	Name = "MonetizationController",
	Items = {} :: { [number]: { [string]: any } },

	PurchaseProcessingChanged = Signal.new(),
	PromptActive = false,
})

function MonetizationController:getMonetizationItemInfo(monetizationType: "Product" | "GamePass", id: number)
	if not TypeCheck.string(monetizationType) then
		warn("monetizationType arg must be a string - monetizationController:getMonetizationItemInfo")
		return
	end

	if not TypeCheck.number(id) or id == 0 then
		return
	end

	if self.Items[id] then
		return self.Items[id]
	end

	local rpcOk: boolean, response: { [string]: any } =
		self.Service:getMonetizationItemInfo(monetizationType, id):await()

	if not rpcOk then
		warn("RPC failed: getMonetizationItemInfo")
		return
	end

	if not TypeCheck.table(response) then
		warn(
			"Server:getMonetizationItemInfo did not return a valid response - monetizationController:getMonetizationItemInfo"
		)
		return
	end

	self.Items[id] = response
	return response
end

function MonetizationController:purchased()
	self.NotificationController:Push({
		Message = `Thanks for your <font color="rgb(157, 255, 0)">purchase</font>! :D`,
		Color = Color3.fromRGB(255, 255, 255),
		Sound = purchaseSfx,
	})
end

function MonetizationController:promptPurchase(purchaseType: string, id: number)
	if not TypeCheck.string(purchaseType) then
		warn("[purchaseType] arg must be a string")
		return
	end

	if not TypeCheck.number(id) then
		warn("[id] arg must be a number")
		return
	end

	if self.PromptActive then
		return
	end
	self.PromptActive = true

	promptSfx:Play()
	self.PurchaseProcessingChanged:Fire(self.PromptActive)

	if purchaseType:lower() == "gamepass" then
		purchaseType = "GamePass"
	end

	MarketplaceService[`Prompt{purchaseType}Purchase`](MarketplaceService, Players.LocalPlayer, id)
	MarketplaceService[`Prompt{purchaseType}PurchaseFinished`]:Once(function()
		self.PromptActive = false
		self.PurchaseProcessingChanged:Fire(self.PromptActive)
	end)
end

function MonetizationController:KnitInit()
	self.Service = knit.GetService("MonetizationService")
	self.Service.UserPurchased:Connect(function()
		self:purchased()
	end)

	self.NotificationController = knit.GetController("NotificationController")
end

return MonetizationController
