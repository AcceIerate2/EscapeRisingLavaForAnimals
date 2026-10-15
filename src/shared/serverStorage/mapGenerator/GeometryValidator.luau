-- Modules
local RoutePlanner = require(script.Parent.RoutePlanner)
local SafeZoneGenerator = require(script.Parent.SafeZoneGenerator)

-->
-- Checks the built map against the route plan using raycasts and spatial queries on the real parts.
local GeometryValidator = {}

function GeometryValidator.Validate(builder, route, reference, zones)
	local config = builder.Config
	local origin = builder.Origin
	local map = builder.Map
	local report = { Checks = {}, Passed = true }

	local function check(name: string, passed: boolean, detail: string)
		table.insert(report.Checks, { Name = name, Passed = passed, Detail = detail })
		report.Passed = report.Passed and passed
	end

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { map }
	params.RespectCanCollide = true

	local up = origin.UpVector
	local function cast(localPoint: Vector3, direction: number, distance: number)
		local result = workspace:Raycast(origin:PointToWorldSpace(localPoint), up * direction * distance, params)
		if not result then
			return nil
		end
		return origin:PointToObjectSpace(result.Position).Y, result.Instance
	end

	-- 1-3. Walk the route centreline: floor where the plan says, no steps, constant headroom.
	local samples = RoutePlanner.Samples(route, 2)
	local floorErrors, stepErrors, headroomErrors = {}, {}, {}
	local minHeadroom = math.huge
	local maxRise = math.tan(math.rad(config.MaxSlope))
	local previous
	for _, sample in samples do
		local expected = sample.Position.Y
		local measured = cast(sample.Position + Vector3.yAxis * 3, -1, 8)
		if not measured or math.abs(measured - expected) > 0.15 then
			table.insert(floorErrors, `{sample.Label} expected {expected} got {measured or "nothing"}`)
		end

		measured = measured or expected
		if previous then
			local run = (Vector3.new(sample.Position.X, 0, sample.Position.Z) - Vector3.new(previous.Position.X, 0, previous.Position.Z)).Magnitude
			local step = math.abs(measured - previous.Measured)
			if step > run * maxRise + 0.3 then
				table.insert(stepErrors, `{previous.Label} -> {sample.Label}: {string.format("%.2f", step)} studs over {string.format("%.1f", run)}`)
			end
		end

		local ceiling, ceilingPart = cast(Vector3.new(sample.Position.X, measured + 0.5, sample.Position.Z), 1, config.Headroom + 3)
		-- The top pad's paths bridge over the open top lap; they aren't a corridor ceiling.
		local underBridge = ceilingPart and builder.TopPad and ceilingPart:IsDescendantOf(builder.TopPad)
		if sample.HasCeiling then
			local room = ceiling and (ceiling - measured) or math.huge
			minHeadroom = math.min(minHeadroom, room)
			if math.abs(room - config.Headroom) > 0.15 then
				table.insert(headroomErrors, `{sample.Label} headroom {room}`)
			end
		elseif ceiling and not underBridge then
			table.insert(headroomErrors, `{sample.Label} unexpected ceiling at +{ceiling - measured}`)
		end

		sample.Measured = measured
		previous = sample
	end
	check("Route floor matches plan", #floorErrors == 0, `{#samples} samples, {#floorErrors} off. {floorErrors[1] or ""}`)
	check("No gaps or steps along route", #stepErrors == 0, `{#stepErrors} problems. {stepErrors[1] or ""}`)
	check("Corridor headroom", #headroomErrors == 0, `min {string.format("%.2f", minHeadroom)} (target {config.Headroom}). {headroomErrors[1] or ""}`)

	-- 4. Entrance and bottom: the route's top landing is flush with the Reference's top (the pit's
	-- rim) and its bottom landing is the pit floor. (The Reference itself is a non-colliding marker.)
	local entranceSide = route.Sides[1]
	local referenceTop = origin:PointToObjectSpace(reference.CFrame * Vector3.new(0, reference.Size.Y / 2, 0)).Y
	local entranceHeight, entrancePart = cast(entranceSide.Corner + Vector3.yAxis * (route.Summit + 3), -1, 6)
	local bottomHeight, bottomPart = cast(entranceSide.Corner + Vector3.yAxis * 3, -1, 6)
	check(
		"Pit hangs from Reference",
		entrancePart == builder.Entrance
			and math.abs((entranceHeight or -1) - referenceTop) < 0.05
			and bottomPart == builder.Floor
			and math.abs(bottomHeight or -1) < 0.05,
		`entrance on {entrancePart and entrancePart.Name or "nothing"} at {entranceHeight} (Reference top {referenceTop}), bottom on {bottomPart and bottomPart.Name or "nothing"}, {route.Summit} studs deep`
	)

	-- 5. Nothing solid sticks out above the rim (pad borders are flat decoration), and the floor is
	-- above the height that kills characters.
	local highest, lowest = -math.huge, math.huge
	for _, part in map:GetDescendants() do
		if part:IsA("BasePart") and part.CanCollide then
			local cframe = origin:ToObjectSpace(part.CFrame)
			local size = part.Size
			local halfY = (math.abs(cframe.XVector.Y) * size.X + math.abs(cframe.YVector.Y) * size.Y + math.abs(cframe.ZVector.Y) * size.Z) / 2
			highest = math.max(highest, cframe.Y + halfY)
			lowest = math.min(lowest, cframe.Y - halfY)
		end
	end
	local bottomWorld = origin:PointToWorldSpace(Vector3.new(0, lowest, 0)).Y
	check(
		"Pit below Reference",
		highest <= referenceTop + config.WallRim + 0.05 and bottomWorld > workspace.FallenPartsDestroyHeight + 50,
		`top {string.format("%.2f", highest - referenceTop)} above the rim, bottom at world Y {bottomWorld} (FallenPartsDestroyHeight {workspace.FallenPartsDestroyHeight})`
	)

	-- 6. Slopes walkable.
	local steepest = 0
	for _, lap in route.Laps do
		for _, run in lap.Runs do
			for _, segment in run.Segments do
				steepest = math.max(steepest, math.deg(math.atan(math.abs(segment.H1 - segment.H0) / (segment.B - segment.A))))
			end
		end
	end
	check("Slopes walkable", steepest <= config.MaxSlope, `steepest {string.format("%.1f", steepest)} deg (limit {config.MaxSlope})`)

	-- 7. Central shaft open: from above, only pads or the pit floor are hit.
	local function isPad(hit)
		return hit and (hit:IsDescendantOf(builder.Folders.ZonePads) or (builder.TopPad and hit:IsDescendantOf(builder.TopPad)))
	end
	local blocked = {}
	local half = route.HoleHalf - 1
	for x = -half, half, 4 do
		for z = -half, half, 4 do
			local _, hit = cast(Vector3.new(x, route.Summit + config.WallRim + 10, z), -1, route.Summit + config.WallRim + 12)
			local fine = hit == builder.Floor or isPad(hit)
			if not fine then
				table.insert(blocked, `({x},{z}) hit {hit and hit:GetFullName() or "nothing"}`)
			end
		end
	end
	check("Central shaft unobstructed", #blocked == 0, `{#blocked} blocked columns. {blocked[1] or ""}`)

	-- 8. Each pad is further from the ramp, and further below the one above it, than the last.
	local gaps, gapErrors = {}, {}
	local previousGap, previousSpacing = 0, 0
	for index, zone in zones do
		local gap = route.HoleHalf - zone.Platform.Size.X / 2
		table.insert(gaps, string.format("%g", gap))
		if gap <= previousGap then
			table.insert(gapErrors, `{zone.Model.Name} gap {gap} is not wider than the zone above`)
		end
		if zone.Platform.Size.X < config.MinPadSize then
			table.insert(gapErrors, `{zone.Model.Name} pad is only {zone.Platform.Size.X} wide`)
		end
		if index > 1 then
			local spacing = zones[index - 1].Elevation - zone.Elevation
			if spacing < previousSpacing or spacing < route.LapHeight then
				table.insert(gapErrors, `{zone.Model.Name} is {spacing} below the zone above, after a spacing of {previousSpacing}`)
			end
			previousSpacing = spacing
		end
		previousGap = gap
	end
	check("Zone pads widen and spread with depth", #gapErrors == 0, `gaps top to bottom: {table.concat(gaps, ", ")}. {gapErrors[1] or ""}`)

	-- 9. Pads don't intersect anything else.
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Include
	overlap.FilterDescendantsInstances = { map }
	overlap.RespectCanCollide = true
	local intersections = {}
	local platforms = {}
	for _, zone in zones do
		table.insert(platforms, zone.Platform)
	end
	if builder.TopPad then
		for _, part in builder.TopPad:GetChildren() do
			if part:IsA("BasePart") and part.CanCollide then
				table.insert(platforms, part)
			end
		end
	end
	for _, platform in platforms do
		for _, hit in workspace:GetPartBoundsInBox(platform.CFrame, platform.Size - Vector3.one * 0.1, overlap) do
			if not hit:IsDescendantOf(platform.Parent) then
				table.insert(intersections, `{platform.Parent.Name}.{platform.Name} x {hit:GetFullName()}`)
			end
		end
	end
	check("Platforms clear of structure", #intersections == 0, `{#platforms} platforms, {#intersections} intersections. {intersections[1] or ""}`)

	-- 10. Top pad: each path is flush with the rim from the wall top to the pad.
	if builder.TopPad then
		local pathErrors = {}
		local paths = 0
		for _, path in builder.TopPad:GetChildren() do
			if path.Name == "Path" then
				paths += 1
				local center = origin:PointToObjectSpace(path.Position)
				local along = if path.Size.X > path.Size.Z then Vector3.xAxis else Vector3.zAxis
				local half = math.max(path.Size.X, path.Size.Z) / 2
				for _, offset in { -half - 1, -half + 1, half - 1, half + 1 } do
					local height = cast(Vector3.new(center.X, route.Summit + 3, center.Z) + along * offset, -1, 6)
					if not height or math.abs(height - route.Summit) > 0.05 then
						table.insert(pathErrors, `{path:GetAttribute("Wall")} path: {height or "nothing"} at {offset} studs along`)
					end
				end
			end
		end
		check("Top pad joined to rim", #pathErrors == 0 and paths > 0, `{paths} paths. {pathErrors[1] or ""}`)
	end

	-- 11. Safe zones: an L of floor level with the corner landing, open to the landing along both of
	-- its outer edges, with the corridor's headroom and the pushed-out walls closing it in.
	local function castAlong(localPoint: Vector3, localDirection: Vector3, distance: number)
		local result = workspace:Raycast(origin:PointToWorldSpace(localPoint), origin:VectorToWorldSpace(localDirection) * distance, params)
		return result and (result.Position - origin:PointToWorldSpace(localPoint)).Magnitude, result and result.Instance
	end

	local safeErrors = {}
	local W, D, E = config.RampWidth, config.SafeZone.Depth, config.SafeZone.Extent
	for _, zone in route.SafeZones do
		local layout = SafeZoneGenerator.Layout(config, zone)
		local u, v = layout.U, layout.V
		local c = zone.Side.Corner
		local h = zone.Height
		local function fail(message)
			table.insert(safeErrors, `{zone.Model.Name}: {message}`)
		end

		-- Floor and headroom across the whole L.
		local middle = W / 2 + D / 2
		local floorPoints = {
			c + u * middle + v * middle, -- outer corner
			c + u * middle,
			c + u * middle - v * (W / 2 + E - 1),
			c + v * middle,
			c + v * middle - u * (W / 2 + E - 1),
		}
		for _, point in floorPoints do
			local floor, hit = cast(point + Vector3.yAxis * (h + 3), -1, 6)
			local ceiling = cast(point + Vector3.yAxis * (h + 0.5), 1, config.Headroom + 3)
			if not hit or hit.Name ~= "Floor" or not hit:IsDescendantOf(zone.Model) or math.abs(floor - h) > 0.05 then
				fail(`floor at ({point.X},{point.Z}) is {floor or "missing"} on {hit and hit.Name or "nothing"}, expected {h}`)
			elseif not ceiling or math.abs(ceiling - h - config.Headroom) > 0.15 then
				fail(`headroom {ceiling and ceiling - h or "open"} at ({point.X},{point.Z})`)
			end
		end

		-- Walking straight off the landing reaches the new wall behind it, D studs past the old one.
		for _, axis in { u, v } do
			for _, along in { -W / 2 + 2, 0, W / 2 - 2 } do
				local across = if axis == u then v else u
				local start = c + axis * (W / 2 - 2) + across * along + Vector3.yAxis * (h + 3)
				local distance, hit = castAlong(start, axis, D + 6)
				if not hit or not hit:IsDescendantOf(zone.Model) or math.abs(distance - (D + 2)) > 0.05 then
					fail(`from the landing toward the {if axis == u then zone.Side.Name else zone.Previous.Name} wall hit {hit and hit:GetFullName() or "nothing"} after {distance}`)
				end
			end
		end

		-- Closed at both ends.
		for _, ending in { { From = c + u * middle - v * (W / 2 + E - 1), Dir = -v }, { From = c + v * middle - u * (W / 2 + E - 1), Dir = -u } } do
			local distance, hit = castAlong(ending.From + Vector3.yAxis * (h + 3), ending.Dir, 3)
			if not hit or math.abs(distance - 1) > 0.05 then
				fail(`open end at ({ending.From.X},{ending.From.Z})`)
			end
		end
	end
	check("Safe zones built into corners", #safeErrors == 0, `{#route.SafeZones} safe zones. {safeErrors[1] or ""}`)

	-- 12. Spawn markers sit on their own pad; monster markers have open space above.
	local markerErrors = {}
	local markerCount = 0
	local markedZones = table.clone(zones)
	if builder.TopZone then
		table.insert(markedZones, builder.TopZone)
	end
	for _, zone in markedZones do
		for _, folderName in { "EggSpawns", "MonsterSpawns" } do
			for _, marker in zone.Model[folderName]:GetChildren() do
				markerCount += 1
				local localPos = origin:PointToObjectSpace(marker.Position)
				local floor, hit = cast(localPos, -1, 3)
				if hit ~= zone.Platform or math.abs(floor - zone.Elevation) > 0.1 then
					table.insert(markerErrors, `{zone.Model.Name}.{marker.Name} not on its pad`)
				end
				if folderName == "MonsterSpawns" and cast(localPos, 1, config.MonsterClearance) then
					table.insert(markerErrors, `{zone.Model.Name}.{marker.Name} lacks clearance`)
				end
			end
		end
	end
	check("Spawn markers placed", #markerErrors == 0, `{markerCount} markers. {markerErrors[1] or ""}`)

	return report
end

return GeometryValidator
