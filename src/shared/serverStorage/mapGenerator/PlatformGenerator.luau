-->
-- Zone pads: as in TemplateTemplate, a pad floats in the middle of the shaft at the top of a lap,
-- reached by jumping the gap from the ramp. Each zone also gets the template's large hitbox.
local PlatformGenerator = {}

-- Four flat white strips just above a platform's top face, forming a frame.
function PlatformGenerator.Border(builder, parent, centerCFrame: CFrame, length: number, width: number, top: number, borderWidth: number, inset: number)
	local folder = builder:Folder("Border", parent)
	local color = builder.Config.ColorPalette.Border
	local height = 0.2
	local y = top + height / 2 + 0.02
	local props = function()
		return { Plain = true, CanCollide = false, CanQuery = false, CastShadow = false }
	end

	local alongX = width / 2 - inset - borderWidth / 2
	local alongZ = length / 2 - inset - borderWidth / 2
	local innerLength = length - 2 * inset
	local innerWidth = width - 2 * inset
	builder:Part("Part", "Edge", folder, centerCFrame * CFrame.new(alongX, y, 0), Vector3.new(borderWidth, height, innerLength), color, props())
	builder:Part("Part", "Edge", folder, centerCFrame * CFrame.new(-alongX, y, 0), Vector3.new(borderWidth, height, innerLength), color, props())
	builder:Part("Part", "Edge", folder, centerCFrame * CFrame.new(0, y, alongZ), Vector3.new(innerWidth, height, borderWidth), color, props())
	builder:Part("Part", "Edge", folder, centerCFrame * CFrame.new(0, y, -alongZ), Vector3.new(innerWidth, height, borderWidth), color, props())
end

-- Depth below the rim of each zone's pad. The gaps between pads grow by a constant ratio, found so
-- that the first gap is ZoneFirstSpacing and the last pad sits one lap above the pit floor.
function PlatformGenerator.ZoneDepths(config, route, count: number)
	local first = config.ZoneFirstDepth
	local depths = { first }
	if count < 2 then
		return depths
	end

	local span = route.Summit - route.LapHeight - first
	local function total(ratio)
		local sum, gap = 0, config.ZoneFirstSpacing
		for _ = 1, count - 1 do
			sum += gap
			gap *= ratio
		end
		return sum
	end
	local low, high = 0.1, 10
	for _ = 1, 60 do
		local ratio = (low + high) / 2
		if total(ratio) < span then
			low = ratio
		else
			high = ratio
		end
	end

	local ratio = (low + high) / 2
	local depth, gap = first, config.ZoneFirstSpacing
	for _ = 2, count do
		depth += gap
		gap *= ratio
		table.insert(depths, math.round(depth / config.RampRise) * config.RampRise)
	end
	return depths
end

-- What every zone has besides its pad: the template hitbox (the zone's lap and a little above its
-- pad) and the folders the egg, animal and monster systems fill.
function PlatformGenerator.ZoneContents(builder, route, model: Model, elevation: number, attributes)
	local hitboxSize = builder.Config.ZoneHitboxSize
	builder:Marker("Hitbox", model, CFrame.new(0, elevation - route.LapHeight + hitboxSize.Y / 2, 0), hitboxSize, {
		CanTouch = true,
		Attributes = attributes,
	})

	builder:Folder("Brainrots", model)
	builder:Folder("EggSpawns", model)
	builder:Folder("MonsterSpawns", model)
end

function PlatformGenerator.Build(builder, route)
	local config = builder.Config
	local zones = {}
	-- The top pad is the first zone, so the jump pads start at the next one.
	local offset = if config.TopPad.Enabled then 1 else 0
	local count = math.min(config.ZoneCount, #config.Zones - offset)
	local depths = PlatformGenerator.ZoneDepths(config, route, count)

	for padIndex = 1, count do
		local zoneIndex = padIndex + offset
		local zoneInfo = config.Zones[zoneIndex]
		-- Every zone deeper is a smaller pad, so its jump is longer.
		local elevation = route.Summit - depths[padIndex]
		local padSize = config.PadSizeTop - (padIndex - 1) * config.PadSizeStep
		local gap = route.HoleHalf - padSize / 2
		local attributes = {
			ZoneId = zoneInfo.Id,
			ZoneIndex = zoneIndex,
			Elevation = elevation,
			Depth = route.Summit - elevation,
			PadGap = gap,
			Color = zoneInfo.Color,
		}

		local model = Instance.new("Model")
		model.Name = `Zone{zoneIndex}`
		for key, value in attributes do
			model:SetAttribute(key, value)
		end
		model.Parent = builder.Folders.ZonePads

		local platform = builder:Part(
			"Part",
			"Platform",
			model,
			CFrame.new(0, elevation - config.PadThickness / 2, 0),
			Vector3.new(padSize, config.PadThickness, padSize),
			zoneInfo.Color,
			{ Material = config.MaterialPalette.Platform, Attributes = attributes, Tags = { "ZonePad" } }
		)
		model.PrimaryPart = platform
		PlatformGenerator.Border(builder, model, CFrame.new(), padSize, padSize, elevation, config.PadBorderWidth, config.PadBorderInset)

		PlatformGenerator.ZoneContents(builder, route, model, elevation, attributes)

		table.insert(zones, {
			Model = model,
			Platform = platform,
			Info = zoneInfo,
			Index = zoneIndex,
			Elevation = elevation,
			PadSize = padSize,
			Gap = gap,
		})
	end

	return zones
end

local PATH_DIRECTIONS = {
	West = Vector3.new(-1, 0, 0),
	East = Vector3.new(1, 0, 0),
	South = Vector3.new(0, 0, -1),
	North = Vector3.new(0, 0, 1),
}

-- The pad at the top of the pit, flush with the rim, with paths out to the walls. It is the first
-- zone (Zones[1]), reached by walking instead of jumping. Returns its zone entry.
function PlatformGenerator.BuildTopPad(builder, route)
	local config = builder.Config
	local settings = config.TopPad
	if not settings.Enabled then
		return nil
	end

	local zoneInfo = config.Zones[1]
	local top = route.Summit
	local attributes = {
		ZoneId = zoneInfo.Id,
		ZoneIndex = 1,
		Elevation = top,
		Depth = 0,
		PadGap = 0,
		Color = zoneInfo.Color,
	}

	local model = Instance.new("Model")
	model.Name = "Zone1"
	for key, value in attributes do
		model:SetAttribute(key, value)
	end
	model.Parent = builder.Folders.ZonePads

	local platform = builder:Part(
		"Part",
		"Platform",
		model,
		CFrame.new(0, top - config.PadThickness / 2, 0),
		Vector3.new(settings.Size, config.PadThickness, settings.Size),
		settings.Color,
		{ Material = config.MaterialPalette.Platform, Attributes = attributes, Tags = { "ZonePad", "TopPad" } }
	)
	model.PrimaryPart = platform
	PlatformGenerator.Border(builder, model, CFrame.new(), settings.Size, settings.Size, top, config.PadBorderWidth, config.PadBorderInset)

	-- Each path runs from the pad's edge to the inside face of a wall.
	local length = config.ShaftSize / 2 - settings.Size / 2
	local center = settings.Size / 2 + length / 2
	for _, wall in settings.Paths do
		local direction = PATH_DIRECTIONS[wall]
		local size = if direction.X ~= 0
			then Vector3.new(length, config.PadThickness, settings.PathWidth)
			else Vector3.new(settings.PathWidth, config.PadThickness, length)
		builder:Part(
			"Part",
			"Path",
			model,
			CFrame.new(direction * center + Vector3.yAxis * (top - config.PadThickness / 2)),
			size,
			builder:LapColor(config.ColorPalette.Landing, route.Config.CircuitCount),
			{ Attributes = { Wall = wall } }
		)
	end

	PlatformGenerator.ZoneContents(builder, route, model, top, attributes)
	return {
		Model = model,
		Platform = platform,
		Info = zoneInfo,
		Index = 1,
		Elevation = top,
		PadSize = settings.Size,
		Gap = 0,
	}
end

return PlatformGenerator
