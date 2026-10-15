-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local spawnTimerConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.spawnTimerConfig)

-->
-- Runs the spawn countdown shown above the top pad. The current round is published as attributes
-- on ReplicatedStorage.SpawnTimer (Rarity, EndsAt in server time) for the clients to display.
local SpawnTimerService = knit.CreateService({
	Name = "SpawnTimerService",
	Client = {},
	SpawnDue = Signal.new(), -- (rarityId: string) the spawning system should listen to this
	Random = Random.new(),
})

-- Public Methods
function SpawnTimerService:GetNext(): (string, number)
	return self.State:GetAttribute("Rarity"), self.State:GetAttribute("EndsAt")
end

-- Private Methods
function SpawnTimerService:pickRarity()
	local total = 0
	for _, rarity in spawnTimerConfig.Rarities do
		total += rarity.Weight
	end
	local roll = self.Random:NextNumber(0, total)
	for _, rarity in spawnTimerConfig.Rarities do
		roll -= rarity.Weight
		if roll <= 0 then
			return rarity
		end
	end
	return spawnTimerConfig.Rarities[#spawnTimerConfig.Rarities]
end

function SpawnTimerService:startRound()
	self.State:SetAttribute("Rarity", self:pickRarity().Id)
	self.State:SetAttribute("EndsAt", workspace:GetServerTimeNow() + spawnTimerConfig.Interval)
end

-- LifeCycle
function SpawnTimerService:KnitInit()
	local state = Instance.new("Folder")
	state.Name = "SpawnTimer"
	state.Parent = ReplicatedStorage
	self.State = state
end

function SpawnTimerService:KnitStart()
	task.spawn(function()
		while true do
			self:startRound()
			task.wait(spawnTimerConfig.Interval)
			self.SpawnDue:Fire(self.State:GetAttribute("Rarity"))
		end
	end)
end

return SpawnTimerService
