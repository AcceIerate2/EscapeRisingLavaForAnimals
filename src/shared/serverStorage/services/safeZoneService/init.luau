-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local checkInterval = 0.2 -- seconds between checks
local regionTag = "SafeZone" -- the invisible Region boxes the map generator puts in each safe zone
local attributeName = "InSafeZone" -- set on the player so the client (and anything else) can read it

-->
-- Server-side record of which players are standing in a safe zone. Checked by position against each
-- safe zone's Region boxes, so it doesn't depend on Touched events or on what the client has streamed.
-- The lava and monster systems should ask IsInSafeZone before hurting a player.
local SafeZoneService = knit.CreateService({
	Name = "SafeZoneService",
	Client = {},
	Changed = Signal.new(), -- (player: Player, isInSafeZone: boolean)
	States = {},
})

-- Public Methods
function SafeZoneService:IsInSafeZone(player: Player): boolean
	return self.States[player] == true
end

-- Private Methods
local function isInside(region: BasePart, position: Vector3): boolean
	local point = region.CFrame:PointToObjectSpace(position)
	local half = region.Size / 2
	return math.abs(point.X) <= half.X and math.abs(point.Y) <= half.Y and math.abs(point.Z) <= half.Z
end

function SafeZoneService:check()
	local regions = CollectionService:GetTagged(regionTag)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")

		local isInSafeZone = false
		if root and humanoid and humanoid.Health > 0 then
			for _, region in regions do
				if region:IsA("BasePart") and region:IsDescendantOf(workspace) and isInside(region, root.Position) then
					isInSafeZone = true
					break
				end
			end
		end
		self:setState(player, isInSafeZone)
	end
end

function SafeZoneService:setState(player: Player, isInSafeZone: boolean)
	if (self.States[player] == true) == isInSafeZone then
		return
	end

	self.States[player] = isInSafeZone
	player:SetAttribute(attributeName, isInSafeZone)
	self.Changed:Fire(player, isInSafeZone)
end

-- LifeCycle
function SafeZoneService:KnitStart()
	Players.PlayerRemoving:Connect(function(player)
		self.States[player] = nil
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed >= checkInterval then
			elapsed = 0
			self:check()
		end
	end)
end

return SafeZoneService
