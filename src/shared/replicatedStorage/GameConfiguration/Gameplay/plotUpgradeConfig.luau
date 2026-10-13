local PlotUpgradeConfig = {}

--[[
	One entry per plot level, in order. Level 1 is what every player starts with.
	Fences: model in ReplicatedStorage.Assets.Fences placed on the plot at this level.
	MaxAnimals: how many animals the player can keep on their plot at this level.
	Cost: cash to upgrade TO this level (level 1 is free).

	Progression: +2 slots every level, and each upgrade costs roughly 16x the one before.
]]
PlotUpgradeConfig.Levels = {
	{ Fences = "Fences_1", MaxAnimals = 6, Cost = 0 },
	{ Fences = "Fences_2", MaxAnimals = 8, Cost = 25_000 },
	{ Fences = "Fences_3", MaxAnimals = 10, Cost = 400_000 },
	{ Fences = "Fences_4", MaxAnimals = 12, Cost = 6_500_000 },
	{ Fences = "Fences_5", MaxAnimals = 14, Cost = 100_000_000 },
	{ Fences = "Fences_6", MaxAnimals = 16, Cost = 1_600_000_000 },
	{ Fences = "Fences_7", MaxAnimals = 18, Cost = 25_000_000_000 },
	{ Fences = "Fences_8", MaxAnimals = 20, Cost = 400_000_000_000 },
}

PlotUpgradeConfig.MaxLevel = #PlotUpgradeConfig.Levels

-- Fence pieces that move or grow on an upgrade pop up out of the ground in a wave from the gate.
PlotUpgradeConfig.Animation = {
	Depth = 7, -- Studs below their final spot each piece starts (hidden under the ground).
	Tilt = 10, -- Max random degrees a piece starts tilted.
	Duration = 0.32, -- Seconds each piece takes to pop up (with a little overshoot).
	Stagger = 0.04, -- Delay between pieces, nearest to the gate first.
	MaxStagger = 0.45,
	Sound = "Plot/PlotUpgrade", -- Path under SoundService.src.Sfx, played for the plot's owner; nil for none.
}

-- Public Methods
function PlotUpgradeConfig.GetLevel(level: number)
	return PlotUpgradeConfig.Levels[math.clamp(level, 1, PlotUpgradeConfig.MaxLevel)]
end

return PlotUpgradeConfig
