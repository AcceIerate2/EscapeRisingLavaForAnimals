-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local scrollTweenInfo = TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local sectionTopPadding = 6

-->
local ShopController = knit.CreateController({
	Name = "ShopController",
	PanelName = "Shop",
	ScrollTween = nil,
})

-- Public Methods
function ShopController:OpenSection(sectionName: string)
	if self.PanelController.ActivePanel ~= self.PanelName then
		self.PanelController:TogglePanel(self.PanelName)
	end

	self:scrollTo(sectionName)
end

-- Private Methods
function ShopController:getOffers(): ScrollingFrame
	local panels = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Panels")
	return panels:WaitForChild(self.PanelName):WaitForChild("Offers")
end

-- Sections are headed by the Title laid out right before them.
function ShopController:getSectionTop(offers: ScrollingFrame, section: GuiObject): GuiObject
	local header = section
	for _, child in offers:GetChildren() do
		if child.Name ~= "Title" or not child:IsA("GuiObject") or not child.Visible or child.LayoutOrder >= section.LayoutOrder then
			continue
		end

		if header == section or child.LayoutOrder > header.LayoutOrder then
			header = child
		end
	end

	return header
end

function ShopController:scrollTo(sectionName: string)
	local offers = self:getOffers()
	local section = offers:FindFirstChild(sectionName)
	if not section or not section:IsA("GuiObject") then
		warn(`[ShopController] No shop section named {sectionName}`)
		return
	end

	local top = self:getSectionTop(offers, section)
	local targetY = top.AbsolutePosition.Y - offers.AbsolutePosition.Y + offers.CanvasPosition.Y - sectionTopPadding
	local maxY = math.max(offers.AbsoluteCanvasSize.Y - offers.AbsoluteWindowSize.Y, 0)

	if self.ScrollTween then
		self.ScrollTween:Cancel()
	end

	self.ScrollTween = TweenService:Create(offers, scrollTweenInfo, {
		CanvasPosition = Vector2.new(0, math.clamp(targetY, 0, maxY)),
	})
	self.ScrollTween:Play()
end

-- LifeCycle
function ShopController:KnitInit()
	self.PanelController = knit.GetController("PanelController")
end

return ShopController
