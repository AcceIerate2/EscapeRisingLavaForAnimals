-- Helpers
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-->
-- The "<RARITY> Spawns in: MM:SS" countdown above the top pad. Each round picks the rarity that
-- spawns next; SpawnTimerService.SpawnDue fires when the timer runs out, for the spawning system.
local SpawnTimerConfig = {}

SpawnTimerConfig.Interval = 150 -- seconds between spawns
SpawnTimerConfig.Height = 18 -- studs above the top pad

-- Weight = how often it is picked. Colors = the gradient across the rarity's name.
SpawnTimerConfig.Rarities = {
	{ Id = "Rare", Weight = 40, Colors = { rgb(255, 225, 90), rgb(255, 180, 30) } },
	{ Id = "Epic", Weight = 25, Colors = { rgb(225, 120, 255), rgb(160, 60, 240) } },
	{ Id = "Legendary", Weight = 16, Colors = { rgb(255, 190, 70), rgb(255, 110, 20) } },
	{ Id = "Mythic", Weight = 10, Colors = { rgb(255, 110, 150), rgb(230, 40, 90) } },
	{ Id = "Secret", Weight = 6, Colors = { rgb(120, 120, 140), rgb(40, 40, 55) } },
	{ Id = "Eternal", Weight = 3, Colors = { rgb(255, 255, 255), rgb(255, 245, 170), rgb(255, 255, 255) } },
}

function SpawnTimerConfig.GetRarity(id: string)
	for _, rarity in SpawnTimerConfig.Rarities do
		if rarity.Id == id then
			return rarity
		end
	end
	return nil
end

return SpawnTimerConfig
