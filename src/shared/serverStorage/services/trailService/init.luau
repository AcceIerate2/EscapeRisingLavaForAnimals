-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Config
local trailsConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.trailsConfig)

-- Essentials
local trailInstanceNames = { "TrailEffect", "TrailAttachment0", "TrailAttachment1" }

-- Helper Functions
local function failed(message: string)
	return {
		Status = false,
		NotificationData = {
			Message = message,
			Color = Color3.fromRGB(255, 0, 0),
			Sound = SoundService.src.Sfx.NotificationSounds.Decline,
		},
	}
end

-->
local TrailService = knit.CreateService({
	Name = "TrailService",
	Client = {},
	Config = trailsConfig,
})

-- Client Exposed Methods
function TrailService.Client:BuyTrail(player: Player, trailId: string)
	return self.Server:BuyTrail(player, trailId)
end

function TrailService.Client:EquipTrail(player: Player, trailId: string)
	return self.Server:EquipTrail(player, trailId)
end

function TrailService.Client:UnequipTrail(player: Player)
	return self.Server:UnequipTrail(player)
end

-- Public Methods
function TrailService:OwnsTrail(player: Player, trailId: string): boolean
	local ownedTrails = self.DataService:GetValue(player, "OwnedTrails")
	return TypeCheck.table(ownedTrails) and ownedTrails[trailId] == true
end

function TrailService:GrantTrail(player: Player, trailId: string)
	assert(TypeCheck.Instance(player), "player arg must be a Player")
	assert(self.Config.GetTrail(trailId), `Invalid trailId: {trailId}`)

	if not self:OwnsTrail(player, trailId) then
		self.DataService:GetValueObject(player, "OwnedTrails"):Insert(nil, trailId, true)
	end

	self:EquipTrail(player, trailId)
end

function TrailService:BuyTrail(player: Player, trailId: string)
	if not TypeCheck.string(trailId) then
		return { Status = false }
	end

	local trail = self.Config.GetTrail(trailId)
	if not trail then
		return { Status = false }
	end

	if self:OwnsTrail(player, trailId) then
		return failed("You already own this trail.")
	end

	if not self.CashService:CanAfford(player, trail.Price) then
		return failed("Not enough cash!")
	end

	self.CashService:ManipulatePlayerCash(player, -trail.Price, "Addition")
	self:GrantTrail(player, trailId)

	return { Status = true }
end

function TrailService:EquipTrail(player: Player, trailId: string)
	if not TypeCheck.string(trailId) or not self:OwnsTrail(player, trailId) then
		return { Status = false }
	end

	self.DataService:GetValueObject(player, "EquippedTrail"):Set(trailId)
	self:applyTrail(player, player.Character)

	return { Status = true }
end

function TrailService:UnequipTrail(player: Player)
	self.DataService:GetValueObject(player, "EquippedTrail"):Set("")
	self:applyTrail(player, player.Character)

	return { Status = true }
end

-- The equipped trail's multiplier on treadmill Speed gains (1 without a trail).
function TrailService:GetSpeedMultiplier(player: Player): number
	local trail = self.Config.GetTrail(self.DataService:GetValue(player, "EquippedTrail") or "")
	return if trail then trail.SpeedMultiplier else 1
end

-- Private Methods
function TrailService:createTrail(root: BasePart, trail)
	local settings = self.Config.Settings

	local attachment0 = InstanceCreator("Attachment", "TrailAttachment0", root, {
		Position = Vector3.new(0, settings.AttachmentHeight, settings.AttachmentBackOffset),
	}) :: Attachment

	local attachment1 = InstanceCreator("Attachment", "TrailAttachment1", root, {
		Position = Vector3.new(0, -settings.AttachmentHeight, settings.AttachmentBackOffset),
	}) :: Attachment

	InstanceCreator("Trail", "TrailEffect", root, {
		Attachment0 = attachment0,
		Attachment1 = attachment1,
		FaceCamera = true,
		MinLength = 0.05,

		Color = trail.Color,
		Lifetime = trail.Lifetime or settings.Lifetime,
		LightEmission = trail.LightEmission or settings.LightEmission,
		Transparency = trail.Transparency or settings.Transparency,
		WidthScale = trail.WidthScale or settings.WidthScale,
	})
end

function TrailService:applyTrail(player: Player, character: Model?)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid then
		return
	end

	for _, name in trailInstanceNames do
		local existing = root:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
	end

	local trail = self.Config.GetTrail(self.DataService:GetValue(player, "EquippedTrail"))
	if trail then
		self:createTrail(root, trail)
	end
end

function TrailService:registerProducts()
	for _, trail in self.Config.Trails do
		if trail.ProductId == 0 then
			continue
		end

		self.MonetizationService.ProductIds[trail.ProductId] = function(player: Player)
			self:GrantTrail(player, trail.Id)
			return true
		end
	end
end

-- LifeCycle
function TrailService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.PlayerService = knit.GetService("PlayerService")
	self.MonetizationService = knit.GetService("MonetizationService")

	self:registerProducts()

	self.PlayerService.CharacterAdded:Connect(function(player: Player, character: Model)
		character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Humanoid", 10)
		self:applyTrail(player, character)
	end)
end

return TrailService
