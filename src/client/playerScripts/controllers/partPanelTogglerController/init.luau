-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local hitboxTag = "PartPanelToggler"
local updateInterval = 0.1

-- Helper Functions
local function overlapsCharacter(hitbox: BasePart, character: Model, overlapParams: OverlapParams): boolean
	for _, part in workspace:GetPartsInPart(hitbox, overlapParams) do
		-- Accessories and equipped tools should not trigger panels by themselves.
		if part.Parent == character then
			return true
		end
	end

	return false
end

-->
local PartPanelTogglerController = knit.CreateController({
	Name = "PartPanelTogglerController",
	Player = Players.LocalPlayer,
	Hitboxes = {},
	CurrentPanel = nil,
	OpenedPanel = nil,
})

-- Private Methods
function PartPanelTogglerController:addHitbox(instance: Instance)
	if instance:IsA("BasePart") then
		self.Hitboxes[instance] = true
	end
end

function PartPanelTogglerController:getOccupiedPanel(): string?
	local character = self.Player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root then
		return nil
	end

	local playerGui = self.Player:FindFirstChildOfClass("PlayerGui")
	local panels = playerGui and playerGui:FindFirstChild("Panels")
	if not panels then
		return nil
	end

	self.OverlapParams.FilterDescendantsInstances = { character }

	local nearestPanel = nil
	local nearestDistance = math.huge

	for hitbox in self.Hitboxes do
		if not hitbox:IsDescendantOf(workspace) then
			continue
		end

		local panelName = hitbox:GetAttribute("PanelName")
		local panel = if typeof(panelName) == "string" then panels:FindFirstChild(panelName) else nil
		if not panel or not panel:IsA("GuiObject") then
			continue
		end

		if not overlapsCharacter(hitbox, character, self.OverlapParams) then
			continue
		end

		-- Keep the current panel stable while overlapping multiple hitboxes.
		if panelName == self.CurrentPanel then
			return panelName
		end

		local distance = (root.Position - hitbox.Position).Magnitude
		if distance < nearestDistance then
			nearestPanel = panelName
			nearestDistance = distance
		end
	end

	return nearestPanel
end

function PartPanelTogglerController:updatePanel()
	local panelName = self:getOccupiedPanel()
	if panelName == self.CurrentPanel then
		return
	end
	self.CurrentPanel = panelName

	-- Close the panel this controller opened previously.
	local previous = self.OpenedPanel
	self.OpenedPanel = nil
	if previous and self.PanelController.ActivePanel == previous then
		self.PanelController:TogglePanel(previous)
	end

	-- Open the panel for the hitbox the player is standing in.
	if panelName and self.PanelController.ActivePanel ~= panelName then
		self.OpenedPanel = panelName
		self.PanelController:TogglePanel(panelName)
	end
end

-- LifeCycle
function PartPanelTogglerController:KnitInit()
	self.PanelController = knit.GetController("PanelController")

	self.OverlapParams = OverlapParams.new()
	self.OverlapParams.FilterType = Enum.RaycastFilterType.Include
	self.OverlapParams.RespectCanCollide = false
	self.OverlapParams.MaxParts = 0
end

function PartPanelTogglerController:KnitStart()
	-- Hitbox Tracking
	self.AddedConnection = CollectionService:GetInstanceAddedSignal(hitboxTag):Connect(function(instance)
		self:addHitbox(instance)
	end)

	self.RemovedConnection = CollectionService:GetInstanceRemovedSignal(hitboxTag):Connect(function(instance)
		self.Hitboxes[instance] = nil
	end)

	for _, instance in CollectionService:GetTagged(hitboxTag) do
		self:addHitbox(instance)
	end

	-- Panel State
	self.PanelConnection = self.PanelController.PanelStateChanged:Connect(function(state)
		if not state.Visible or state.PanelName ~= self.OpenedPanel then
			self.OpenedPanel = nil
		end
	end)

	-- Update Loop
	local elapsed = 0
	self.UpdateConnection = RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < updateInterval or not self.Player:FindFirstChild("ClientReady") then
			return
		end

		elapsed = 0
		self:updatePanel()
	end)
end

return PartPanelTogglerController
