-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local GiftController = knit.CreateController({
	Name = "GiftController",
	Locked = false,

	RemoveButton = Signal.new(),
	AddButton = Signal.new(),

	UpdateExitButton = Signal.new(),

	Id = 0,
	PurchaseType = "",
	ReturnPanelName = "Gift",
})

function GiftController:pushNotification(notificationData)
	if not TypeCheck.table(notificationData) then
		return
	end

	self.NotificationController:Push({
		Message = notificationData.Message,
		Color = notificationData.NotificationColor,
		Sound = notificationData.NotificationSound,
	})
end

function GiftController:updateReturnPanelName(newReturnPanelName: string)
	self.ReturnPanelName = newReturnPanelName
	self.UpdateExitButton:Fire(self.ReturnPanelName)
end

function GiftController:updatePurchaseType(newPurchaseType: string)
	self.PurchaseType = newPurchaseType
end

function GiftController:updateId(newId: number)
	self.Id = newId
end

function GiftController:gift(otherPlayerUserId: number)
	if self.Locked then
		return
	end

	if not TypeCheck.number(otherPlayerUserId) then
		return
	end

	local otherPlayer = Players:GetPlayerByUserId(otherPlayerUserId)
	if not otherPlayer then
		self:pushNotification({
			Message = "Player Left.",
			Color = Color3.fromRGB(255, 0, 0),
			Sound = SoundService:WaitForChild("src")
				:WaitForChild("Sfx")
				:WaitForChild("NotificationSounds")
				:WaitForChild("Decline"),
		})
		return
	end

	self.Locked = true
	self.Service
		:newGiftRequest(otherPlayerUserId, self.Id, self.PurchaseType)
		:andThen(function(response: {
			Status: boolean,
			NotificationData: {
				Message: string,
				Color: Color3,
				Sound: Sound,
			},
		})
			warn(response.Status, response.NotificationData)

			if TypeCheck.table(response.NotificationData) then
				self:pushNotification({
					Message = response.NotificationData.Message,
					Color = response.NotificationData.Color,
					Sound = response.NotificationData.Sound,
				})
			end

			if not response.Status then
				self.Locked = false
				return
			end

			self.MonetizationController:promptPurchase(self.PurchaseType, self.Id)
			self.Locked = false
		end)
		:catch(warn)
end

function GiftController:KnitInit()
	self.Service = knit.GetService("GiftService")
	self.NotificationController = knit.GetController("NotificationController")
	self.MonetizationController = knit.GetController("MonetizationController")

	self.Players = {}
	for _, player: Player in pairs(Players:GetPlayers()) do
		if player == Players.LocalPlayer then
			continue
		end
		table.insert(self.Players, player)
	end

	Players.PlayerAdded:Connect(function(playerAdded: Player)
		table.insert(self.Players, playerAdded)
		self.AddButton:Fire(playerAdded.UserId)
	end)

	Players.PlayerRemoving:Connect(function(playerRemoved: Player)
		local _index = table.find(self.Players, playerRemoved)
		if not _index then
			return
		end
		table.remove(self.Players, _index)
		self.RemoveButton:Fire(playerRemoved.UserId)
	end)
end

return GiftController
