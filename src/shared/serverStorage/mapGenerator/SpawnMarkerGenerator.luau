-->
-- Invisible markers on each zone pad for the egg and monster systems to use later.
local SpawnMarkerGenerator = {}

local function farEnough(point: Vector3, others, spacing: number): boolean
	for _, other in others do
		if (point - other).Magnitude < spacing then
			return false
		end
	end
	return true
end

local function marker(builder, zone, folder, spawnType: string, index: number, point: Vector3)
	builder:Marker(`{spawnType}Spawn{index}`, folder, CFrame.new(point.X, zone.Elevation + 0.5, point.Z), Vector3.one, {
		Attributes = {
			ZoneId = zone.Info.Id,
			ZoneIndex = zone.Index,
			Elevation = zone.Elevation,
			SpawnType = spawnType,
		},
		Tags = { `{spawnType}Spawn` },
	})
end

function SpawnMarkerGenerator.Build(builder, zones)
	local config = builder.Config
	local rng = builder.Random

	for _, zone in zones do
		local reach = zone.PadSize / 2 - config.SpawnInset
		local taken = {}

		-- Monsters: the pad's corners and edge midpoints, shuffled, for the most room to move.
		local monsterSpots = {
			Vector3.new(reach, 0, reach),
			Vector3.new(-reach, 0, reach),
			Vector3.new(reach, 0, -reach),
			Vector3.new(-reach, 0, -reach),
			Vector3.new(0, 0, reach),
			Vector3.new(0, 0, -reach),
			Vector3.new(reach, 0, 0),
			Vector3.new(-reach, 0, 0),
		}
		for i = #monsterSpots, 2, -1 do
			local j = rng:NextInteger(1, i)
			monsterSpots[i], monsterSpots[j] = monsterSpots[j], monsterSpots[i]
		end
		for index = 1, math.min(config.MonsterSpawnCount, #monsterSpots) do
			local point = monsterSpots[index]
			table.insert(taken, point)
			marker(builder, zone, zone.Model.MonsterSpawns, "Monster", index, point)
		end

		-- Eggs: random points inside the inset area, kept apart from each other and the monsters.
		local placed = 0
		for _ = 1, 500 do
			if placed >= config.EggSpawnCount then
				break
			end

			local point = Vector3.new(rng:NextNumber(-reach, reach), 0, rng:NextNumber(-reach, reach))
			if farEnough(point, taken, config.EggSpawnSpacing) then
				placed += 1
				table.insert(taken, point)
				marker(builder, zone, zone.Model.EggSpawns, "Egg", placed, point)
			end
		end
	end
end

return SpawnMarkerGenerator
