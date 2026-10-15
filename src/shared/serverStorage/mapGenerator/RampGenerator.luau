-- Modules
local RoutePlanner = require(script.Parent.RoutePlanner)

-- Essentials
local EPS = 1e-3
local UP = Vector3.yAxis

-->
-- Builds the ring of solid geometry the route is carved through, the way TemplateTemplate does:
-- between the ceiling of one lap (floor + Headroom) and the floor of the lap above, the ring is
-- solid. Each wall section of that band is at most three parts:
--   a flipped wedge (sloped ceiling of the lower lap), a block, and a wedge (ramp of the upper lap).
local RampGenerator = {}

-- Solid wedge between the line rising from ha (at distance a) to hb (at b) and its far side:
-- below the line for a ramp, above it (flipped) for a ceiling.
local function slopedWedge(builder, parent, name, side, a, b, ha, hb, color, flipped, props)
	local W = builder.Config.RampWidth
	local center = side.Origin + side.Dir * ((a + b) / 2) + UP * ((ha + hb) / 2)
	local rising = if hb > ha then side.Dir else -side.Dir

	-- A WedgePart is tallest at its local +Z face; flipped, it is thickest at local +Z.
	local cframe = if flipped
		then CFrame.fromMatrix(center, UP:Cross(rising), -UP, -rising)
		else CFrame.fromMatrix(center, UP:Cross(rising), UP, rising)
	return builder:Part("WedgePart", name, parent, cframe, Vector3.new(W, math.abs(hb - ha), b - a), color, props)
end

local function runBlock(builder, parent, name, side, a, b, bottom, top, color, props)
	local W = builder.Config.RampWidth
	local center = side.Origin + side.Dir * ((a + b) / 2) + UP * ((bottom + top) / 2)
	local cframe = CFrame.fromMatrix(center, UP:Cross(side.Dir), UP, side.Dir)
	return builder:Part("Part", name, parent, cframe, Vector3.new(W, top - bottom, b - a), color, props)
end

local function cornerBlock(builder, parent, name, side, bottom, top, color, props)
	local W = builder.Config.RampWidth
	local center = side.Corner + UP * ((bottom + top) / 2)
	return builder:Part("Part", name, parent, CFrame.new(center), Vector3.new(W, top - bottom, W), color, props)
end

-- Heights at both ends of [a, b], taken from the segment covering the interval's middle so a
-- kink exactly at a breakpoint uses the right slope.
local function lineBetween(segments, a: number, b: number): (number, number)
	local segment = RoutePlanner.SegmentAt(segments, (a + b) / 2)
	local function at(p: number): number
		return segment.H0 + (segment.H1 - segment.H0) * ((p - segment.A) / (segment.B - segment.A))
	end
	return at(a), at(b)
end

local function breakpoints(lower, upper, length: number)
	local points = { 0, length }
	for _, list in { lower, upper } do
		for _, segment in list do
			table.insert(points, segment.A)
			table.insert(points, segment.B)
		end
	end
	table.sort(points)

	local unique = {}
	for _, point in points do
		if #unique == 0 or point - unique[#unique] > EPS then
			table.insert(unique, point)
		end
	end
	return unique
end

-- One wall section of a band. `lower` = ceiling segments of the lap below (or nil at the bottom),
-- `upper` = floor segments of the lap above.
function RampGenerator.BuildRunBand(builder, route, side, lower, upper, lapIndex: number)
	local config = builder.Config
	local palette = config.ColorPalette
	local headroom = config.Headroom
	local attributes = { Lap = lapIndex, Wall = side.Name }

	local structure = builder:Folder(`Lap{lapIndex}`, builder.Folders.Structure)
	local ramps = builder:Folder(`Lap{lapIndex}`, builder.Folders.Ramps)
	local connections = builder:Folder(`Lap{lapIndex}`, builder.Folders.Connections)
	local structureColor = builder:LapColor(palette.Structure, lapIndex)
	local rampColor = builder:LapColor(palette.Ramp, lapIndex)
	local landingColor = builder:LapColor(palette.Landing, lapIndex)

	local points = breakpoints(lower or {}, upper, route.RunLength)
	for i = 1, #points - 1 do
		local a, b = points[i], points[i + 1]
		local ua, ub = lineBetween(upper, a, b)
		local la, lb = 0, 0
		if lower then
			la, lb = lineBetween(lower, a, b)
			la += headroom
			lb += headroom
		end

		local lowMin, lowMax = math.min(la, lb), math.max(la, lb)
		local upMin, upMax = math.min(ua, ub), math.max(ua, ub)
		assert(lowMax <= upMin + EPS, `Lap {lapIndex} {side.Name}: ceiling overlaps the floor above`)

		if lowMax - lowMin > EPS then
			slopedWedge(builder, structure, "Ceiling", side, a, b, la, lb, structureColor, true, { Attributes = attributes })
		end

		if upMin - lowMax > EPS then
			local isFlatFloor = upMax - upMin <= EPS
			runBlock(
				builder,
				if isFlatFloor then connections else structure,
				if isFlatFloor then "Flat" else "Support",
				side,
				a,
				b,
				lowMax,
				upMin,
				if isFlatFloor then landingColor else structureColor,
				{ Attributes = attributes }
			)
		end

		if upMax - upMin > EPS then
			slopedWedge(builder, ramps, "Ramp", side, a, b, ua, ub, rampColor, false, { Attributes = attributes })
		end
	end
end

function RampGenerator.BuildCornerBand(builder, side, bottom: number, top: number, lapIndex: number, name: string?)
	if top - bottom <= EPS then
		return nil
	end

	local connections = builder:Folder(`Lap{lapIndex}`, builder.Folders.Connections)
	local color = builder:LapColor(builder.Config.ColorPalette.Landing, lapIndex)
	return cornerBlock(builder, connections, name or "Landing", side, bottom, top, color, {
		Attributes = { Lap = lapIndex, Corner = side.Name },
	})
end

function RampGenerator.Build(builder, route)
	local headroom = builder.Config.Headroom

	-- Lap 1 sits on the pit floor (lower = nil -> solid down to height 0).
	for lapIndex, lap in route.Laps do
		local below = route.Laps[lapIndex - 1]
		for sideIndex, side in route.Sides do
			local floor = lap.Corners[sideIndex].Height
			local ceilingBelow = if below then below.Corners[sideIndex].Height + headroom else 0
			RampGenerator.BuildCornerBand(builder, side, ceilingBelow, floor, lapIndex)

			local lower = if below then below.Runs[sideIndex].Segments else nil
			RampGenerator.BuildRunBand(builder, route, side, lower, lap.Runs[sideIndex].Segments, lapIndex)
		end
	end

	-- The entrance landing closes the top lap at its starting corner, flush with the Reference's top.
	local last = route.Laps[#route.Laps]
	local entranceSide = route.Sides[1]
	builder.Entrance = RampGenerator.BuildCornerBand(builder, entranceSide, last.Corners[1].Height + headroom, route.Summit, #route.Laps + 1, "EntranceLanding")
end

return RampGenerator
