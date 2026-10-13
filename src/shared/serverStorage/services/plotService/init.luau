-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config
local plotUpgradeConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.plotUpgradeConfig)

-- Essentials
local fenceAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Fences")

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
local PlotService = knit.CreateService({
	Name = "PlotService",
	Client = {},
	PlayerPlots = {},
	PlotOwners = {},
	FenceHomes = {}, -- [plot]: CFrame every fence model is pivoted to
	UpgradeConfig = plotUpgradeConfig,
})

-- Client Exposed Methods
function PlotService.Client:GetPlot(player: Player): Model?
	return self.Server:GetPlayerPlot(player)
end

function PlotService.Client:UpgradePlot(player: Player)
	return self.Server:UpgradePlot(player)
end

-- Public Methods
function PlotService:GetPlayerPlot(player: Player): Model?
	return self.PlayerPlots[player]
end

function PlotService:GetPlotLevel(player: Player): number
	local level = self.DataService:GetValue(player, "PlotLevel")
	return math.clamp(if typeof(level) == "number" then level else 1, 1, self.UpgradeConfig.MaxLevel)
end

function PlotService:GetMaxAnimals(player: Player): number
	return self.UpgradeConfig.GetLevel(self:GetPlotLevel(player)).MaxAnimals
end

function PlotService:UpgradePlot(player: Player)
	local plot = self:GetPlayerPlot(player)
	if not plot then
		return { Status = false }
	end

	local nextLevel = self:GetPlotLevel(player) + 1
	if nextLevel > self.UpgradeConfig.MaxLevel then
		return failed("Your plot is already max level!")
	end

	local cost = self.UpgradeConfig.Levels[nextLevel].Cost
	if not self.CashService:CanAfford(player, cost) then
		return failed(`You need ${NumberShortner(cost)} to expand your plot!`)
	end

	self.CashService:ManipulatePlayerCash(player, -cost, "Addition")
	self.DataService:GetValueObject(player, "PlotLevel"):Set(nextLevel)
	self:applyLevel(plot, nextLevel)

	return {
		Status = true,
		NotificationData = {
			Message = `Plot expanded! You can now keep <font color="rgb(120, 235, 80)">{self.UpgradeConfig.Levels[nextLevel].MaxAnimals}</font> animals.`,
			Color = Color3.fromRGB(255, 255, 255),
			Sound = SoundService.src.Sfx.NotificationSounds.Accept,
		},
	}
end

function PlotService:LoadPlot(player: Player): Model?
	local existingPlot = self:GetPlayerPlot(player)
	if existingPlot then
		return existingPlot
	end
	if player.Parent ~= Players then
		return nil
	end

	for _, plot in ipairs(self.Plots:GetChildren()) do
		local spawnPart = plot:FindFirstChild("Spawn")
		if not plot:IsA("Model") or not spawnPart or not spawnPart:IsA("BasePart") or self.PlotOwners[plot] then
			continue
		end

		self.PlayerPlots[player] = plot
		self.PlotOwners[plot] = player
		plot:AddPersistentPlayer(player)
		plot:SetAttribute("OwnerUserId", player.UserId)
		self:updateOverhead(plot, player)
		self:applyLevel(plot, self:GetPlotLevel(player))
		return plot
	end

	return nil
end

function PlotService:DisconnectPlot(player: Player)
	local plot = self:GetPlayerPlot(player)
	if not plot then
		return
	end

	self.PlayerPlots[player] = nil
	self.PlotOwners[plot] = nil
	plot:RemovePersistentPlayer(player)
	plot:SetAttribute("OwnerUserId", nil)
	self:updateOverhead(plot, nil)
	self:applyLevel(plot, 1)
end

function PlotService:SpawnCharacter(player: Player, character: Model)
	local plot = self:GetPlayerPlot(player)
	if not plot then
		return
	end

	local root = character:WaitForChild("HumanoidRootPart", 10)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not root or not root:IsA("BasePart") or not humanoid or not humanoid:IsA("Humanoid") then
		return
	end
	if player.Parent ~= Players or player.Character ~= character or self:GetPlayerPlot(player) ~= plot or humanoid.Health <= 0 then
		return
	end

	local spawnPart = plot:FindFirstChild("Spawn")
	if not spawnPart or not spawnPart:IsA("BasePart") then
		return
	end

	local height = spawnPart.Size.Y / 2 + character:GetExtentsSize().Y / 2 + 0.5
	character:PivotTo(spawnPart.CFrame * CFrame.new(0, height, 0))
	root.AssemblyLinearVelocity = Vector3.zero
	root.AssemblyAngularVelocity = Vector3.zero
end

-- Private Methods
-- Swaps in the fence model for this level. Every Fences_N shares its pivot on the gate side,
-- so pivoting each one to the plot's original fence pivot lines them up and they grow inwards.
function PlotService:applyLevel(plot: Model, level: number)
	local levelData = self.UpgradeConfig.GetLevel(level)
	plot:SetAttribute("PlotLevel", level)
	plot:SetAttribute("MaxAnimals", levelData.MaxAnimals)

	local current = plot:FindFirstChild("Fences")
	if current and current:GetAttribute("FenceAsset") == levelData.Fences then
		return
	end

	local asset = fenceAssets:FindFirstChild(levelData.Fences)
	if not asset then
		warn(`[PlotService] Missing fence asset {levelData.Fences}`)
		return
	end

	local fences = asset:Clone()
	fences.Name = "Fences"
	fences:SetAttribute("FenceAsset", levelData.Fences)
	fences:PivotTo(self.FenceHomes[plot])
	if current then
		current:Destroy()
	end
	fences.Parent = plot
end

function PlotService:updateOverhead(plot: Model, player: Player?)
	local overhead = plot:FindFirstChild("OverheadUI")
	local ui = overhead and overhead:FindFirstChild("UI")
	if not ui or not ui:IsA("BillboardGui") then
		return
	end

	local nameLabel = ui:FindFirstChild("Name")
	local avatar = ui:FindFirstChild("Avatar")
	if nameLabel and nameLabel:IsA("TextLabel") then
		nameLabel.Text = if player then player.DisplayName else "N/A"
	end
	if avatar and avatar:IsA("ImageLabel") then
		avatar.Image = if player then `rbxthumb://type=AvatarHeadShot&id={player.UserId}&w=420&h=420` else ""
	end
	ui.Enabled = player ~= nil
end

-- LifeCycle
function PlotService:KnitInit()
	self.PlayerService = knit.GetService("PlayerService")
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.Plots = workspace:WaitForChild("Plots")

	for _, plot in ipairs(self.Plots:GetChildren()) do
		if plot:IsA("Model") then
			plot.ModelStreamingMode = Enum.ModelStreamingMode.PersistentPerPlayer
			plot:SetAttribute("OwnerUserId", nil)
			self:updateOverhead(plot, nil)

			local fences = plot:FindFirstChild("Fences")
			if fences and fences:IsA("Model") then
				self.FenceHomes[plot] = fences:GetPivot()
				self:applyLevel(plot, 1)
			end
		end
	end

	self.PlayerService.CharacterAdded:Connect(function(player: Player, character: Model)
		self:SpawnCharacter(player, character)
	end)
end

return PlotService
