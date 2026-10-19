-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local pitArea = require(ReplicatedStorage.src.utility.pitArea)

-- Config
local nightConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.nightConfig)

-->
-- Runs the day/night cycle. The current phase is published on ReplicatedStorage.Night for
-- NightController to show: Phase ("Day" or "Night") and EndsAt in server time. When night falls the
-- NightPart blocks the pit and everyone in it is sent to Workspace.SpawnLocation; at sunrise every egg resets.
local NightService = knit.CreateService({
	Name = "NightService",
	Client = {},
	Config = nightConfig,
	NightStarted = Signal.new(),
	NightEnded = Signal.new(),
	-- (player) sent to the spawn from the pit as night fell: the egg-carrying system should take their eggs.
	SentHome = Signal.new(),
	-- Fired at sunrise: the egg system should clear every egg and spawn a fresh set.
	EggsReset = Signal.new(),
})

-- Public Methods
function NightService:IsNight(): boolean
	return self.State:GetAttribute("Phase") == "Night"
end

-- Private Methods
-- Whether a position is in the pit: the same area as the lava HUD (pads, safe zones, ramps), reaching
-- higher above the rim so players jumping or falling in are caught too.
function NightService:isInPit(position: Vector3): boolean
	local map = workspace:FindFirstChild("GeneratedMap")
	return pitArea(map, position, nightConfig.AboveRim, nightConfig.PocketReach) ~= nil
end

function NightService:sendPitPlayersHome()
	local spawn = workspace:FindFirstChild(nightConfig.SpawnName)
	if not spawn or not spawn:IsA("BasePart") then
		warn(`NightService: no Workspace.{nightConfig.SpawnName} to send players to`)
		return
	end

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and self:isInPit(root.Position) then
			self.SentHome:Fire(player)
			root.AssemblyLinearVelocity = Vector3.zero
			character:PivotTo(spawn.CFrame * CFrame.new(0, spawn.Size.Y / 2 + nightConfig.SpawnHeight, 0))
		end
	end
end

function NightService:setPhase(phase: string, length: number)
	self.State:SetAttribute("Phase", phase)
	self.State:SetAttribute("EndsAt", workspace:GetServerTimeNow() + length)
end

function NightService:setPartBlocking(blocking: boolean)
	local part = workspace:FindFirstChild(nightConfig.PartName)
	if part and part:IsA("BasePart") then
		-- Only collision changes here; NightController animates how it looks on each client.
		part.CanCollide = blocking
		part.CanQuery = blocking
		part:SetAttribute("Blocking", blocking)
	end
end

function NightService:runCycle()
	while true do
		self:setPhase("Day", nightConfig.DayLength)
		task.wait(nightConfig.DayLength)

		self:setPhase("Night", nightConfig.NightLength)
		self:setPartBlocking(true)
		self:sendPitPlayersHome()
		self.NightStarted:Fire()
		task.wait(nightConfig.NightLength)

		-- Sunrise: the pit opens and every egg resets.
		self:setPartBlocking(false)
		self.NightEnded:Fire()
		self.EggsReset:Fire()
	end
end

-- LifeCycle
function NightService:KnitInit()
	local state = Instance.new("Folder")
	state.Name = "Night"
	state.Parent = ReplicatedStorage
	self.State = state

	-- Hidden until the first night (it's left visible in Studio so it can be edited).
	local part = workspace:FindFirstChild(nightConfig.PartName)
	if part and part:IsA("BasePart") then
		part.Transparency = 1
		part.Anchored = true
		-- Its countdown SurfaceGuis are left on in Studio for editing; clients switch them on at night.
		for _, gui in part:GetChildren() do
			if gui:IsA("SurfaceGui") then
				gui.Enabled = false
			end
		end
	end
	self:setPartBlocking(false)
end

function NightService:KnitStart()
	task.spawn(self.runCycle, self)
end

return NightService
