-- Modules
local SafeZoneGenerator = require(script.Parent.SafeZoneGenerator)

-- Essentials
local EPS = 1e-3

-->
-- The four outer walls of the square pit, from its floor up to the Reference's top, plus the floor.
-- Safe zones push the walls out at their corners, so those stretches of wall are cut away.
local ShaftGenerator = {}

-- The parts of an axis-aligned box left after removing another: at most six boxes.
local function subtract(box, cut)
	local lo, hi = box.Min, box.Max
	local cMin, cMax = lo:Max(cut.Min), hi:Min(cut.Max)
	local overlap = cMax - cMin
	if overlap.X <= EPS or overlap.Y <= EPS or overlap.Z <= EPS then
		return { box }
	end

	local pieces = {}
	local function add(min: Vector3, max: Vector3)
		local size = max - min
		if size.X > EPS and size.Y > EPS and size.Z > EPS then
			table.insert(pieces, { Min = min, Max = max })
		end
	end
	add(lo, Vector3.new(hi.X, cMin.Y, hi.Z)) -- below
	add(Vector3.new(lo.X, cMax.Y, lo.Z), hi) -- above
	add(Vector3.new(lo.X, cMin.Y, lo.Z), Vector3.new(cMin.X, cMax.Y, hi.Z))
	add(Vector3.new(cMax.X, cMin.Y, lo.Z), Vector3.new(hi.X, cMax.Y, hi.Z))
	add(Vector3.new(cMin.X, cMin.Y, lo.Z), Vector3.new(cMax.X, cMax.Y, cMin.Z))
	add(Vector3.new(cMin.X, cMin.Y, cMax.Z), Vector3.new(cMax.X, cMax.Y, hi.Z))
	return pieces
end

function ShaftGenerator.Build(builder, route, reference)
	local config = builder.Config
	local folder = builder.Folders.Walls
	local half = config.ShaftSize / 2
	local height = route.Summit + config.WallRim
	local color = config.ColorPalette.Wall

	-- Thicken the walls to fill the Reference's footprint so the pit meets the ground around it.
	local thickness = config.WallThickness
	if config.FitWallsToReference then
		thickness = math.max(thickness, (math.min(reference.Size.X, reference.Size.Z) - config.ShaftSize) / 2)
	end

	-- East/West walls run the full outer length; North/South fit between them (as in the template).
	local outer = config.ShaftSize + 2 * thickness
	local walls = {
		{ Name = "WestWall", Min = Vector3.new(-half - thickness, 0, -outer / 2), Max = Vector3.new(-half, height, outer / 2) },
		{ Name = "EastWall", Min = Vector3.new(half, 0, -outer / 2), Max = Vector3.new(half + thickness, height, outer / 2) },
		{ Name = "SouthWall", Min = Vector3.new(-half, 0, -half - thickness), Max = Vector3.new(half, height, -half) },
		{ Name = "NorthWall", Min = Vector3.new(-half, 0, half), Max = Vector3.new(half, height, half + thickness) },
	}

	local cuts = {}
	for _, zone in route.SafeZones do
		for _, cut in SafeZoneGenerator.Layout(config, zone).Cuts do
			table.insert(cuts, cut)
		end
	end

	for _, wall in walls do
		local pieces = { wall }
		for _, cut in cuts do
			local remaining = {}
			for _, piece in pieces do
				for _, rest in subtract(piece, cut) do
					table.insert(remaining, rest)
				end
			end
			pieces = remaining
		end

		-- One band per lap so each can take its lap's colour.
		for _, piece in pieces do
			local firstLap = math.floor(piece.Min.Y / route.LapHeight + EPS) + 1
			local lastLap = math.ceil(piece.Max.Y / route.LapHeight - EPS)
			for lap = firstLap, lastLap do
				local bottom = math.max(piece.Min.Y, (lap - 1) * route.LapHeight)
				local top = math.min(piece.Max.Y, lap * route.LapHeight)
				if top - bottom > EPS then
					local min = Vector3.new(piece.Min.X, bottom, piece.Min.Z)
					local max = Vector3.new(piece.Max.X, top, piece.Max.Z)
					builder:Part("Part", wall.Name, folder, CFrame.new((min + max) / 2), max - min, builder:LapColor(color, lap), {
						Attributes = { Lap = lap },
					})
				end
			end
		end
	end

	builder.Floor = builder:Part(
		"Part",
		"Floor",
		folder,
		CFrame.new(0, -config.FloorThickness / 2, 0),
		Vector3.new(outer, config.FloorThickness, outer),
		builder:LapColor(config.ColorPalette.Landing, 1)
	)
end

return ShaftGenerator
