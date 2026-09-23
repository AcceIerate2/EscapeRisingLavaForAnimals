-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Tween Config
local tweenInfo = TweenInfo.new(0.15)
local hideTweenInfo = TweenInfo.new(0.25)

-->
local Notifications = {
	_nextLayoutOrder = 0,
}

function Notifications:tweenSize(notificationCard: CanvasGroup, size: UDim2): Tween
	local tween = utility
		.createTween(notificationCard, tweenInfo, {
			Size = size,
		})
		.Play()
	return tween
end

function Notifications:showNotification(notificationData, id: number)
	assert(TypeCheck.table(notificationData), "notificationData arg must be a Table")
	assert(TypeCheck.number(id), "id must be a number")

	local notificationCard = self.Template:Clone() :: CanvasGroup
	notificationCard.Size = UDim2.fromScale(0, 0)

	notificationCard.Name = tostring(id)
	notificationCard.LayoutOrder = -id

	local label = notificationCard:WaitForChild("Label") :: TextLabel
	utility.updateText(label, notificationData.Message)
	utility.updateTextColor(label, notificationData.Color or Color3.fromRGB(255, 255, 255))

	if TypeCheck.string(notificationData.Icon) then
		local icon = notificationCard:WaitForChild("Icon") :: ImageLabel
		icon.Image = notificationData.Icon
		icon.ImageColor3 = notificationData.IconColor or Color3.fromRGB(255, 255, 255)
		icon.Visible = true
	end

	notificationCard.Parent = self.Container
	notificationCard.Visible = true

	local defaultSize = notificationCard:GetAttribute("DefaultSize")
	self:tweenSize(notificationCard, defaultSize)
end

function Notifications:hideNotification(id: number)
	if not TypeCheck.number(id) then
		return
	end

	local notificationCard = self.Container:FindFirstChild(tostring(id)) :: Frame
	if not TypeCheck.Instance(notificationCard) then
		warn(`Could not find NotificationCard Named: [{id}]`)
		return
	end

	task.spawn(function()
		utility
			.createTween(notificationCard, hideTweenInfo, { GroupTransparency = 1 })
			.Play()
			.Completed(function()
				notificationCard:Destroy()
			end)
			.Destroy()
	end)
end

function Notifications:updateContainerPosition(position: UDim2)
	task.spawn(function()
		utility
			.createTween(self.Container, tweenInfo, {
				Position = position or self.Container:GetAttribute("DefaultPosition"),
			})
			.Play()
			.Completed()
			.Destroy()
	end)
end

function Notifications:Init(player: Player)
	ReplicatedStorage:WaitForChild("src"):WaitForChild("AssetsToLoad"):WaitForChild("NotificationsScreenGui").Name =
		"Notifications"
	ReplicatedStorage:WaitForChild("src"):WaitForChild("AssetsToLoad"):WaitForChild("Notifications").Parent =
		player.PlayerGui

	self.Container = player.PlayerGui:WaitForChild("Notifications"):WaitForChild("CanvasGroup")
	self.Container:SetAttribute("DefaultPosition", self.Container.Position)

	self.Template = self.Container:WaitForChild("Template")

	self.Controller = knit.GetController("NotificationController")
	self.Controller.showNotification:Connect(function(notificationData, id)
		self:showNotification(notificationData, id)
	end)

	self.Controller.hideNotification:Connect(function(id)
		self:hideNotification(id)
	end)

	self.Controller.canvasPositionChanged:Connect(function(position: UDim2)
		assert(TypeCheck.UDim2(position), "position arg must be a UDim2")
		self:updateContainerPosition(position)
	end)

	self.Controller.canvasPositionReset:Connect(function()
		self:updateContainerPosition()
	end)
end

return Notifications
