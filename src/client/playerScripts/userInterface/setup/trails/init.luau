-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config
local trailsConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.trailsConfig)

-- Essentials
local unequipStyle = { -- Matches the Close button.
	Gradient = ColorSequence.new(Color3.fromRGB(255, 63, 69), Color3.fromRGB(218, 10, 28)),
	Depth = Color3.fromRGB(135, 0, 12),
}

-- Helper Functions
local function getButtonStyle(button: GuiButton)
	return {
		Gradient = button.Gradient.Color,
		Depth = button.Depth3D.BackgroundColor3,
	}
end

local function setButtonStyle(button: GuiButton, style)
	button.Gradient.Color = style.Gradient
	button.Depth3D.BackgroundColor3 = style.Depth
	button.Depth3D.SquareTop.BackgroundColor3 = style.Depth
end

-->
local Trails = {
	Cards = {},
	OwnedTrails = {},
	EquippedTrail = "",
}

-- Private Methods
function Trails:linkButton(button: GuiButton, action: string, trailId: string)
	button:SetAttribute("Type", "Action")
	button:SetAttribute("Action", action)
	button:SetAttribute("TrailId", trailId)
	button:AddTag("GuiButton")
end

function Trails:loadRobuxPrice(button: GuiButton, productId: number)
	task.spawn(function()
		local info = self.MonetizationController:getMonetizationItemInfo("Product", productId)
		if TypeCheck.table(info) and TypeCheck.number(info.PriceInRobux) then
			utility.updateText(button.Label, `{info.PriceInRobux} R$`)
		end
	end)
end

function Trails:createCard(template: Frame, trail, layoutOrder: number)
	local card = template:Clone()
	card.Name = trail.Id
	card.LayoutOrder = layoutOrder
	card.Visible = true

	-- Display
	card.Gradient.Color = trail.CardColor
	card.TrailArt.Image = trail.Art
	utility.updateText(card.TrailName, trail.Name)
	utility.updateText(card.Rarity, trail.Rarity)
	utility.updateText(card.Multiplier.Value, `<font color="#69FF26">x{trail.SpeedMultiplier}</font> Speed`)
	utility.updateText(card.BuyCash.Label, `${NumberShortner(trail.Price)}`)

	-- Buttons
	self:linkButton(card.Action, "ToggleTrail", trail.Id)
	self:linkButton(card.BuyCash, "BuyTrailCash", trail.Id)

	if trail.ProductId == 0 then
		-- No Robux option, so the cash button takes the full width.
		card.BuyRobux:Destroy()
		card.BuyCash.Size = card.Action.Size
	else
		self:linkButton(card.BuyRobux, "BuyTrailRobux", trail.Id)
		self:loadRobuxPrice(card.BuyRobux, trail.ProductId)
	end

	card.Parent = template.Parent
	self.Cards[trail.Id] = card
end

function Trails:refresh()
	for trailId, card in self.Cards do
		local owned = self.OwnedTrails[trailId] == true
		local equipped = self.EquippedTrail == trailId

		card.Action.Visible = owned
		card.BuyCash.Visible = not owned

		local buyRobux = card:FindFirstChild("BuyRobux")
		if buyRobux then
			buyRobux.Visible = not owned
		end

		utility.updateText(card.Action.Label, if equipped then "Unequip" else "Equip")
		setButtonStyle(card.Action, if equipped then unequipStyle else self.EquipStyle)
	end
end

-- LifeCycle
function Trails:Init(_player: Player)
	local dataController = knit.GetController("DataController")
	self.MonetizationController = knit.GetController("MonetizationController")

	-- Cards
	local trailList = utility.getPanel("Trails"):WaitForChild("TrailList")
	local template = trailList:WaitForChild("Template")
	template.Visible = false
	self.EquipStyle = getButtonStyle(template.Action)

	for index, trail in trailsConfig.Trails do
		self:createCard(template, trail, index)
	end

	-- Player Data
	self.OwnedTrails = dataController:GetValue("OwnedTrails")
	self.EquippedTrail = dataController:GetValue("EquippedTrail")
	self:refresh()

	dataController:GetValueChangedSignal("OwnedTrails"):Connect(function(ownedTrails)
		self.OwnedTrails = ownedTrails
		self:refresh()
	end)

	dataController:GetValueChangedSignal("EquippedTrail"):Connect(function(equippedTrail)
		self.EquippedTrail = equippedTrail
		self:refresh()
	end)
end

return Trails
