-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local lavaConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.lavaConfig)
local tickInterval = 0.1 -- seconds between damage checks / wave updates
local bodyHeight = 5 -- studs from a character's feet that count as touching lava

-->
-- Runs the lava waves. Each rising wave is a Folder of attributes under ReplicatedStorage.LavaState;
-- clients draw the slabs from them (LavaController) and this service works out the same heights from
-- the same numbers to damage players. Heights are in the pit's local space: studs above its floor.
local LavaService = knit.CreateService({
	Name = "LavaService",
	Client = {},
	Config = lavaConfig,
	WaveStarted = Signal.new(), -- (wave: Folder)
	WaveEnded = Signal.new(), -- (wave: Folder)
	LastHit = {}, -- [wave][player] = os.clock() of the last hit
	WaveCount = 0,
	Random = Random.new(),
})

-- Public Methods
function LavaService:GetWaves(): { Folder }
	return self.State:GetChildren()
end

function LavaService:GetHeight(wave: Folder): number
	return lavaConfig.HeightAt(wave:GetAttributes(), workspace:GetServerTimeNow())
end

-- Stops every wave rising for a while (Stop Lava product).
function LavaService:Freeze(duration: number)
	self:setSpeedMultiplier(0, duration)
end

-- Slows every wave for a while (Slow Lava product).
function LavaService:Slow(duration: number, multiplier: number)
	self:setSpeedMultiplier(multiplier, duration)
end

-- Private Methods
function LavaService:getPit()
	local map = workspace:FindFirstChild("GeneratedMap")
	local cframe = map and map:GetAttribute("ReferenceCFrame")
	local size = map and map:GetAttribute("ReferenceSize")
	local depth = map and map:GetAttribute("Depth")
	local shaftSize = map and map:GetAttribute("ShaftSize")
	if not (cframe and size and depth and shaftSize) then
		return nil
	end

	return {
		Origin = cframe * CFrame.new(0, size.Y / 2 - depth, 0), -- pit floor centre, Y up
		Depth = depth,
		HalfExtent = shaftSize / 2,
	}
end

local function pickWeighted(rng: Random, list)
	local total = 0
	for _, item in list do
		total += item.Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, item in list do
		roll -= item.Weight
		if roll <= 0 then
			return item
		end
	end
	return list[#list]
end

-- Re-anchors a wave at its current height so clients and server stay in step after a speed change.
function LavaService:reanchor(wave: Folder, speed: number)
	local now = workspace:GetServerTimeNow()
	wave:SetAttribute("StartHeight", lavaConfig.HeightAt(wave:GetAttributes(), now))
	wave:SetAttribute("StartTime", now)
	wave:SetAttribute("Speed", speed)
end

function LavaService:setSpeedMultiplier(multiplier: number, duration: number)
	self.SpeedMultiplier = multiplier
	for _, wave in self:GetWaves() do
		self:reanchor(wave, wave:GetAttribute("BaseSpeed") * multiplier)
	end

	self.EffectToken = (self.EffectToken or 0) + 1
	local token = self.EffectToken
	task.delay(duration, function()
		if self.EffectToken ~= token then
			return
		end
		self.SpeedMultiplier = 1
		for _, wave in self:GetWaves() do
			self:reanchor(wave, wave:GetAttribute("BaseSpeed"))
		end
	end)
end

function LavaService:spawnWave(pit)
	local lavaType = pickWeighted(self.Random, lavaConfig.Types)
	local mutation = pickWeighted(self.Random, lavaConfig.Mutations)
	local template = self.Templates:FindFirstChild(mutation.Template)
	local thickness = if template then template.Size.Y else 5

	self.WaveCount += 1
	local wave = Instance.new("Folder")
	wave.Name = `Wave{self.WaveCount}`
	wave:SetAttribute("Type", lavaType.Id)
	wave:SetAttribute("Mutation", mutation.Id)
	wave:SetAttribute("BaseSpeed", lavaType.Speed)
	wave:SetAttribute("Speed", lavaType.Speed * (self.SpeedMultiplier or 1))
	wave:SetAttribute("StartHeight", 0)
	wave:SetAttribute("StartTime", workspace:GetServerTimeNow())
	-- Stops just under the top pad, which sits flush with the rim.
	wave:SetAttribute("TopHeight", pit.Depth - 2 - lavaConfig.TopGap)
	wave:SetAttribute("HalfExtent", pit.HalfExtent)
	wave:SetAttribute("Thickness", thickness)
	wave.Parent = self.State

	self.LastHit[wave] = {}
	self.WaveStarted:Fire(wave)
end

function LavaService:removeWave(wave: Folder)
	self.LastHit[wave] = nil
	wave:Destroy()
	self.WaveEnded:Fire(wave)
end

-- Damages players a wave's slab is passing through, unless they are in a safe zone.
function LavaService:damagePlayers(pit, wave: Folder, height: number)
	local now = os.clock()
	local thickness = wave:GetAttribute("Thickness")
	local shape = lavaConfig.Shape(wave:GetAttribute("Mutation"), pit.HalfExtent, height)
	local hits = self.LastHit[wave]

	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not root or not humanoid or humanoid.Health <= 0 then
			continue
		end

		local point = pit.Origin:PointToObjectSpace(root.Position)
		local feet = point.Y - (humanoid.HipHeight + root.Size.Y / 2)
		if feet > height or feet + bodyHeight < height - thickness then
			continue
		end

		local inside = false
		for _, area in shape do
			if point.X >= area.MinX and point.X <= area.MaxX and point.Z >= area.MinZ and point.Z <= area.MaxZ then
				inside = true
				break
			end
		end
		if not inside or self.SafeZoneService:IsInSafeZone(player) then
			continue
		end

		if now - (hits[player] or 0) >= lavaConfig.DamageCooldown then
			hits[player] = now
			humanoid:TakeDamage(lavaConfig.Damage)
		end
	end
end

function LavaService:update()
	local pit = self:getPit()
	if not pit then
		return
	end

	for _, wave in self:GetWaves() do
		local height = self:GetHeight(wave)
		if height >= wave:GetAttribute("TopHeight") then
			local reachedAt = wave:GetAttribute("ReachedTopAt")
			if not reachedAt then
				wave:SetAttribute("ReachedTopAt", os.clock())
			elseif os.clock() - reachedAt >= lavaConfig.TopHoldTime then
				self:removeWave(wave)
				continue
			end
		end
		self:damagePlayers(pit, wave, height)
	end
end

function LavaService:runSpawner()
	while true do
		local pit = self:getPit()
		if pit and #self:GetWaves() < lavaConfig.MaxWaves then
			self:spawnWave(pit)
		end
		task.wait(lavaConfig.SpawnInterval)
	end
end

-- LifeCycle
function LavaService:KnitInit()
	self.SafeZoneService = knit.GetService("SafeZoneService")
	self.Templates = ReplicatedStorage:WaitForChild(lavaConfig.TemplateFolder)

	local state = Instance.new("Folder")
	state.Name = "LavaState"
	state.Parent = ReplicatedStorage
	self.State = state
end

function LavaService:KnitStart()
	Players.PlayerRemoving:Connect(function(player)
		for _, hits in self.LastHit do
			hits[player] = nil
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed >= tickInterval then
			elapsed = 0
			self:update()
		end
	end)

	task.spawn(self.runSpawner, self)
end

return LavaService
