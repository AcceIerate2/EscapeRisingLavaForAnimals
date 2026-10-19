-- Essentials
local EPS = 1e-4

-- Helpers
local function shuffle(list, rng: Random)
	for i = #list, 2, -1 do
		local j = rng:NextInteger(1, i)
		list[i], list[j] = list[j], list[i]
	end
end

-->
-- Plans the route as pure data (no parts). Local coordinates: X east, Z north, Y up, origin at the
-- centre of the pit's floor. Like TemplateTemplate, each lap is four ramps, one per wall, joined by
-- flat corner landings; going up it runs counter-clockwise from above:
-- NW corner -> west wall -> SW -> south wall -> SE -> east wall -> NE -> north wall -> NW.
local RoutePlanner = {}

function RoutePlanner.GetSides(config)
	local W = config.RampWidth
	local corner = config.ShaftSize / 2 - W / 2 -- corner landing centres
	local runStart = config.ShaftSize / 2 - W -- where a wall's ramp begins

	local function side(name, cornerX, cornerZ, originX, originZ, dirX, dirZ)
		local dir = Vector3.new(dirX, 0, dirZ)
		return {
			Name = name,
			Corner = Vector3.new(cornerX, 0, cornerZ), -- the landing this wall's ramp starts from
			Origin = Vector3.new(originX, 0, originZ), -- centreline point where the ramp starts
			Dir = dir, -- uphill direction along the wall
			Inward = Vector3.yAxis:Cross(dir).Unit * -1, -- toward the open middle of the shaft
		}
	end

	return {
		side("West", -corner, corner, -corner, runStart, 0, -1),
		side("South", -corner, -corner, -runStart, -corner, 1, 0),
		side("East", corner, -corner, corner, -runStart, 0, 1),
		side("North", corner, corner, runStart, corner, -1, 0),
	}
end

function RoutePlanner.SegmentAt(segments, distance: number)
	for _, segment in segments do
		if distance >= segment.A - EPS and distance <= segment.B + EPS then
			return segment
		end
	end
	return segments[#segments]
end

function RoutePlanner.HeightAt(segments, distance: number): number
	local segment = RoutePlanner.SegmentAt(segments, distance)
	local alpha = (distance - segment.A) / (segment.B - segment.A)
	return segment.H0 + (segment.H1 - segment.H0) * alpha
end

function RoutePlanner.Plan(config)
	local route = {
		Config = config,
		Sides = RoutePlanner.GetSides(config),
		RunLength = config.ShaftSize - 2 * config.RampWidth,
		LapHeight = 4 * config.RampRise,
		Laps = {},
	}
	route.Summit = config.CircuitCount * route.LapHeight
	route.HoleHalf = config.ShaftSize / 2 - config.RampWidth

	for lapIndex = 1, config.CircuitCount do
		local base = (lapIndex - 1) * route.LapHeight
		local lap = { Index = lapIndex, Base = base, Corners = {}, Runs = {} }

		for sideIndex, side in route.Sides do
			local height = base + (sideIndex - 1) * config.RampRise
			lap.Corners[sideIndex] = { Side = side, Height = height }
			-- One straight ramp the full length of the wall.
			lap.Runs[sideIndex] = {
				Side = side,
				Segments = { { A = 0, B = route.RunLength, H0 = height, H1 = height + config.RampRise } },
			}
		end

		route.Laps[lapIndex] = lap
	end

	RoutePlanner.PlanSafeZones(route, Random.new(config.Seed))
	return route
end

-- Safe zones sit in the outside corner of a turn: a pocket dug out of the two walls behind the
-- corner landing (see SafeZoneGenerator). Picked per lap with the seed; never the corner of the lap
-- below, never the pit floor's corner, and never so close to the rim that it would reach the ground.
function RoutePlanner.PlanSafeZones(route, rng: Random)
	local config = route.Config
	local settings = config.SafeZone
	local pocketTop = (settings.Height or config.Headroom) + settings.FloorThickness

	route.SafeZones = {}
	local previousPicks = {}
	for lapIndex, lap in route.Laps do
		local candidates = {}
		for sideIndex, corner in lap.Corners do
			local firstCorner = lapIndex == 1 and sideIndex == 1
			local belowGround = corner.Height + pocketTop <= route.Summit - settings.MinCover
			if not firstCorner and belowGround and not previousPicks[sideIndex] then
				table.insert(candidates, sideIndex)
			end
		end
		shuffle(candidates, rng)

		local picks = {}
		for n = 1, math.min(settings.PerLap, #candidates) do
			local sideIndex = candidates[n]
			local corner = lap.Corners[sideIndex]
			local zone = {
				Lap = lapIndex,
				SideIndex = sideIndex,
				Side = corner.Side,
				Previous = route.Sides[(sideIndex - 2) % #route.Sides + 1],
				Height = corner.Height,
			}
			corner.SafeZone = zone
			picks[sideIndex] = true
			table.insert(route.SafeZones, zone)
		end
		previousPicks = picks
	end

	-- Numbered from the top down, like the zones.
	table.sort(route.SafeZones, function(a, b)
		return a.Height > b.Height
	end)
	for index, zone in route.SafeZones do
		zone.Index = index
	end
end

-- Walking-surface sample points along the route centreline, bottom to top, for validation.
function RoutePlanner.Samples(route, step: number)
	local samples = {}
	local lastLap = #route.Laps

	for lapIndex, lap in route.Laps do
		for sideIndex, side in route.Sides do
			local corner = lap.Corners[sideIndex]
			table.insert(samples, {
				Position = side.Corner + Vector3.yAxis * corner.Height,
				-- The top lap is open to the sky, except its first landing under the entrance landing.
				HasCeiling = lapIndex < lastLap or sideIndex == 1,
				Label = `Lap{lapIndex} {side.Name} corner`,
			})

			local run = lap.Runs[sideIndex]
			local count = math.ceil(route.RunLength / step)
			for i = 0, count do
				local distance = math.clamp(i * route.RunLength / count, 0.5, route.RunLength - 0.5)
				table.insert(samples, {
					Position = side.Origin + side.Dir * distance + Vector3.yAxis * RoutePlanner.HeightAt(run.Segments, distance),
					HasCeiling = lapIndex < lastLap,
					Label = `Lap{lapIndex} {side.Name} wall`,
				})
			end
		end
	end

	table.insert(samples, {
		Position = route.Sides[1].Corner + Vector3.yAxis * route.Summit,
		HasCeiling = false,
		Label = "Entrance landing",
	})
	return samples
end

return RoutePlanner
