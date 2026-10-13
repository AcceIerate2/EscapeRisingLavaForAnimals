-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Config
local devConfig = require(ReplicatedStorage.src.GameConfiguration.General.devConfig)

-->
local DevService = knit.CreateService({
	Name = "DevService",
	Client = {},
	Config = devConfig,
	Spawned = {}, -- [Player]: Folder of test buttons
})

-- Private Methods
-- Cash goes through CashService like real income; other values are set directly. Never below 0.
function DevService:applyChange(player: Player, dataKey: string, change: number)
	local current = self.DataService:GetValue(player, dataKey)
	if typeof(current) ~= "number" then
		return
	end
	change = math.max(change, -current)
	if change == 0 then
		return
	end

	if dataKey == "Cash" then
		self.CashService:ManipulatePlayerCash(player, change, "Addition")
		return
	end

	local valueObject = self.DataService:GetValueObject(player, dataKey)
	valueObject:Set(current + change)
end

function DevService:createButton(folder: Folder, button, cframe: CFrame)
	local part = InstanceCreator("Part", button.Label, folder, {
		Anchored = true,
		CanCollide = true,
		Size = Vector3.new(4, 1, 4),
		CFrame = cframe,
		Color = button.Color,
		Material = Enum.Material.Neon,
	}) :: Part

	local billboard = InstanceCreator("BillboardGui", "Label", part, {
		Size = UDim2.fromOffset(160, 44),
		StudsOffset = Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		MaxDistance = 120,
	})
	local text = InstanceCreator("TextLabel", "Text", billboard, {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text = button.Label,
		TextColor3 = button.Color,
		TextScaled = true,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy),
	})
	InstanceCreator("UIStroke", "UIStroke", text, { Thickness = 3 })

	local detector = InstanceCreator("ClickDetector", "ClickDetector", part, { MaxActivationDistance = 60 }) :: ClickDetector
	detector.MouseClick:Connect(function(player: Player)
		self:applyChange(player, button.DataKey, math.random(button.Amount[1], button.Amount[2]))
	end)
end

function DevService:spawnButtons(player: Player)
	local buttons = self.Config.TestButtons
	local plot = self.PlotService:GetPlayerPlot(player)
	local gates = plot and plot:FindFirstChild("Gates")
	if self.Spawned[player] or not gates then
		return
	end

	local folder = InstanceCreator("Folder", `DevTestButtons_{player.Name}`, workspace) :: Folder
	self.Spawned[player] = folder

	local origin = CFrame.new(gates:GetPivot().Position + buttons.Offset)
	for index, button in buttons.Buttons do
		self:createButton(folder, button, origin * CFrame.new(0, 0, (index - 1) * buttons.Spacing))
	end
end

-- LifeCycle
function DevService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.PlotService = knit.GetService("PlotService")
	self.PlayerService = knit.GetService("PlayerService")
end

function DevService:KnitStart()
	if not RunService:IsStudio() or not self.Config.TestButtons.Enabled then
		return
	end

	-- The plot is assigned before the character is hooked up, so the first spawn is a safe moment.
	self.PlayerService.CharacterAdded:Connect(function(player: Player)
		self:spawnButtons(player)
	end)

	game:GetService("Players").PlayerRemoving:Connect(function(player: Player)
		if self.Spawned[player] then
			self.Spawned[player]:Destroy()
			self.Spawned[player] = nil
		end
	end)
end

return DevService
