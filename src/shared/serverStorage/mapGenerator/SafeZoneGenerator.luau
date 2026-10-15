-- Roblox Services
local ServerStorage = game:GetService("ServerStorage")

-->
--[[
	Safe zones: an L-shaped floor in the outside corner of a turn, between the corner landing and the
	two walls that meet there (top-down, the path's L wraps around the inside of the safe zone's L).

	The walls are pushed out to make room: ShaftGenerator cuts the Cuts boxes out of them and this
	builds the pocket in their place - a floor level with the landing, a ceiling level with the
	corridor's, and new walls behind it. The path itself is untouched; the pocket is open to it along
	the landing's two outer edges and carries on Extent studs along each wall.

	Decoration: if ServerStorage[AssetFolder] has the model named by SafeZone.Decoration, a copy goes in
	every safe zone. Build the template relative to SafeZoneGenerator.Frame (pivot at the origin).
]]
local SafeZoneGenerator = {}

-- Box from ranges along u and v (horizontal unit axes out of the corner centre) and along Y.
local function cornerBox(c: Vector3, u: Vector3, v: Vector3, u0, u1, v0, v1, y0, y1)
	local a = c + u * u0 + v * v0
	local b = c + u * u1 + v * v1
	return {
		Min = Vector3.new(math.min(a.X, b.X), y0, math.min(a.Z, b.Z)),
		Max = Vector3.new(math.max(a.X, b.X), y1, math.max(a.Z, b.Z)),
	}
end

-- Frame on the floor at the corner landing's centre, X toward this corner's wall and Y up. Every
-- safe zone is the same shape in its own frame.
function SafeZoneGenerator.Frame(zone): CFrame
	return CFrame.fromMatrix(zone.Side.Corner + Vector3.yAxis * zone.Height, -zone.Side.Inward, Vector3.yAxis)
end

-- Every box of one safe zone, in the map's local space.
function SafeZoneGenerator.Layout(config, zone)
	local settings = config.SafeZone
	local W, D, E = config.RampWidth, settings.Depth, settings.Extent
	local t, bt = settings.FloorThickness, settings.WallThickness
	local h, P = zone.Height, config.Headroom
	local u, v = -zone.Side.Inward, -zone.Previous.Inward -- toward this corner's wall, toward the previous wall
	local c = zone.Side.Corner
	local face, back = W / 2, W / 2 + D -- the old wall face and the new one, measured from the corner centre

	local function box(u0, u1, v0, v1, y0, y1)
		return cornerBox(c, u, v, u0, u1, v0, v1, y0, y1)
	end

	-- A: along this corner's wall, from Extent past the landing round to the outer corner.
	-- B: along the previous wall, from Extent past the landing to where A begins.
	local floorA = { -W / 2 - E, back }
	local floorB = { -W / 2 - E, face }
	return {
		U = u,
		V = v,
		Cuts = {
			box(face, back + bt, -W / 2 - E - bt, back + bt, h - t, h + P + t),
			box(-W / 2 - E - bt, back + bt, face, back + bt, h - t, h + P + t),
		},
		Floors = {
			box(face, back, floorA[1], floorA[2], h - t, h),
			box(floorB[1], floorB[2], face, back, h - t, h),
		},
		Ceilings = {
			box(face, back, floorA[1], floorA[2], h + P, h + P + t),
			box(floorB[1], floorB[2], face, back, h + P, h + P + t),
		},
		Walls = {
			box(back, back + bt, -W / 2 - E, back + bt, h - t, h + P + t), -- behind A, round the outer corner
			box(-W / 2 - E, back, back, back + bt, h - t, h + P + t), -- behind B
			box(face, back + bt, -W / 2 - E - bt, -W / 2 - E, h - t, h + P + t), -- end of A
			box(-W / 2 - E - bt, -W / 2 - E, face, back + bt, h - t, h + P + t), -- end of B
		},
		Regions = {
			box(face, back, floorA[1], floorA[2], h, h + P),
			box(floorB[1], floorB[2], face, back, h, h + P),
		},
	}
end

function SafeZoneGenerator.Build(builder, route)
	local config = builder.Config
	local palette = config.ColorPalette
	local assets = ServerStorage:FindFirstChild(config.AssetFolder)
	local decoration = assets and assets:FindFirstChild(config.SafeZone.Decoration)

	for _, zone in route.SafeZones do
		local attributes = {
			SafeZoneIndex = zone.Index,
			Lap = zone.Lap,
			Corner = zone.Side.Name,
			Elevation = zone.Height,
			Depth = route.Summit - zone.Height,
		}

		local model = Instance.new("Model")
		model.Name = `SafeZone{zone.Index}`
		for key, value in attributes do
			model:SetAttribute(key, value)
		end
		model.Parent = builder.Folders.SafeZones
		zone.Model = model

		local layout = SafeZoneGenerator.Layout(config, zone)
		local function part(name, box, color, props)
			return builder:Part("Part", name, model, CFrame.new((box.Min + box.Max) / 2), box.Max - box.Min, color, props)
		end

		for _, box in layout.Floors do
			part("Floor", box, config.SafeZone.Color, { Attributes = attributes, Tags = { "SafeZoneFloor" } })
		end
		for _, box in layout.Ceilings do
			part("Ceiling", box, builder:LapColor(palette.Structure, zone.Lap))
		end
		for _, box in layout.Walls do
			part("Wall", box, builder:LapColor(palette.Wall, zone.Lap))
		end

		-- Invisible volume over the floor for detecting players.
		for _, box in layout.Regions do
			builder:Marker("Region", model, CFrame.new((box.Min + box.Max) / 2), box.Max - box.Min, {
				CanTouch = true,
				Attributes = attributes,
				Tags = { "SafeZone" },
			})
		end

		if decoration then
			local deco = decoration:Clone()
			deco.Name = "Deco"
			deco:PivotTo(builder.Origin * SafeZoneGenerator.Frame(zone))
			deco.Parent = model
		end
	end
end

return SafeZoneGenerator
