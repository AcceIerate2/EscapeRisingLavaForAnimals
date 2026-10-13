-- Builds the six-zone spiral beneath Workspace.Reference.
local ref = workspace:FindFirstChild("Reference")
assert(ref and ref:IsA("BasePart"), "Workspace.Reference must be a BasePart")
assert(not ref:FindFirstChild("ArenaStructure"), "Remove or rename the existing ArenaStructure before rebuilding")

local history = game:GetService("ChangeHistoryService")
local recording = history:TryBeginRecording("BuildSpiralArena", "Build six-zone wedge spiral")
local arena = Instance.new("Model")
arena.Name = "ArenaStructure"
arena:SetAttribute("Layout", "SixZoneSpiral")
local origin = ref.CFrame * CFrame.new(0, ref.Size.Y / 2, 0)
local scaleX, scaleZ = ref.Size.X / 150, ref.Size.Z / 150
local drop = 8
local zoneFlights = { 2, 4, 5, 6, 7, 8 }
local colors = {
	Color3.fromRGB(28, 167, 229),
	Color3.fromRGB(104, 213, 49),
	Color3.fromRGB(244, 191, 42),
	Color3.fromRGB(225, 103, 35),
	Color3.fromRGB(192, 78, 200),
	Color3.fromRGB(105, 86, 218),
}
local wallColor = Color3.fromRGB(84, 85, 114)
local rampColor = Color3.fromRGB(130, 119, 147)
local green = Color3.fromRGB(95, 224, 33)
local darkGreen = Color3.fromRGB(36, 118, 35)
local corners = {
	Vector3.new(-65, 0, -65),
	Vector3.new(65, 0, -65),
	Vector3.new(65, 0, 65),
	Vector3.new(-65, 0, 65),
}

local function group(name, parent)
	local model = Instance.new("Model")
	model.Name = name
	model.Parent = parent or arena
	return model
end

local function world(point)
	return origin:PointToWorldSpace(Vector3.new(point.X * scaleX, point.Y, point.Z * scaleZ))
end

local function part(parent, name, size, point, color, className)
	local p = Instance.new(className or "Part")
	p.Name = name
	p.Size = Vector3.new(size.X * scaleX, size.Y, size.Z * scaleZ)
	p.CFrame = origin * CFrame.new(point.X * scaleX, point.Y, point.Z * scaleZ)
	p.Anchored = true
	p.Color = color
	p.Material = Enum.Material.Plastic
	p.TopSurface = Enum.SurfaceType.Studs
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.LeftSurface = Enum.SurfaceType.Studs
	p.RightSurface = Enum.SurfaceType.Studs
	p.FrontSurface = Enum.SurfaceType.Studs
	p.BackSurface = Enum.SurfaceType.Studs
	p.Parent = parent
	return p
end

local path = group("DescendingPath")
local zones = group("Zones")
local rooms = group("RecessedSafeZones")
local shell = group("ShaftWalls")
local flights = {}
local alcoves = {}
local endpoints = {}
local height = 0
local index = 1
local flightNumber = 0

local function landing(number, cornerIndex, y)
	local point = corners[cornerIndex]
	return part(path, "Landing" .. number, Vector3.new(20, 2, 20), Vector3.new(point.X, y - 1, point.Z), rampColor)
end
landing(0, index, height)

for zoneNumber, flightCount in zoneFlights do
	for _ = 1, flightCount do
		flightNumber += 1
		local nextIndex = index % 4 + 1
		local from, to = corners[index], corners[nextIndex]
		local direction = (to - from).Unit
		local startPoint = from + direction * 10 + Vector3.new(0, height, 0)
		local endPoint = to - direction * 10 + Vector3.new(0, height - drop, 0)
		local midpoint = (startPoint + endPoint) / 2
		local forward = (world(midpoint + direction) - world(midpoint)).Unit
		local run = (world(Vector3.new(endPoint.X, 0, endPoint.Z)) - world(Vector3.new(startPoint.X, 0, startPoint.Z))).Magnitude
		local width = if direction.X ~= 0 then 20 * scaleZ else 20 * scaleX
		local wedge = part(path, "Wedge" .. flightNumber, Vector3.new(20, drop, 110), midpoint, rampColor, "WedgePart")
		wedge.Size = Vector3.new(width, drop, run)
		-- A wedge's high end is +Z; its low end faces downhill along -Z.
		wedge.CFrame = CFrame.lookAt(world(midpoint), world(midpoint) + forward)
		wedge:SetAttribute("Zone", zoneNumber)
		wedge:SetAttribute("StartHeight", height)
		wedge:SetAttribute("EndHeight", height - drop)
		table.insert(flights, wedge)
		table.insert(endpoints, { startPoint, endPoint })
		height -= drop
		index = nextIndex
		landing(flightNumber, index, height)
	end

	local corner = corners[index]
	local xSign, zSign = math.sign(corner.X), math.sign(corner.Z)
	local zone = group("Zone" .. zoneNumber, zones)
	zone:SetAttribute("ZoneIndex", zoneNumber)
	zone:SetAttribute("Depth", -height)
	zone:SetAttribute("RampSectionsFromPreviousZone", flightCount)
	local deck = part(zone, "Platform", Vector3.new(72, 2, 72), Vector3.new(0, height - 1, 0), colors[zoneNumber])
	zone.PrimaryPart = deck
	for _, sign in { -1, 1 } do
		local a = part(
			zone,
			"BorderX" .. sign,
			Vector3.new(0.7, 0.06, 69),
			Vector3.new(sign * 34.5, height + 0.03, 0),
			Color3.fromRGB(219, 241, 255)
		)
		local b = part(
			zone,
			"BorderZ" .. sign,
			Vector3.new(69, 0.06, 0.7),
			Vector3.new(0, height + 0.03, sign * 34.5),
			Color3.fromRGB(219, 241, 255)
		)
		a.Material = Enum.Material.Neon
		b.Material = Enum.Material.Neon
		a.TopSurface = Enum.SurfaceType.Smooth
		b.TopSurface = Enum.SurfaceType.Smooth
	end
	local bridgeFrom = world(Vector3.new(xSign * 30, height - 0.8, zSign * 30))
	local bridgeTo = world(Vector3.new(xSign * 65, height - 0.8, zSign * 65))
	local bridge = part(zone, "LandingBridge", Vector3.new(9, 1.6, 1), Vector3.zero, colors[zoneNumber])
	bridge.Size = Vector3.new(9 * math.min(scaleX, scaleZ), 1.6, (bridgeTo - bridgeFrom).Magnitude)
	bridge.CFrame = CFrame.lookAt((bridgeFrom + bridgeTo) / 2, bridgeTo)

	table.insert(alcoves, { X = xSign, Z = zSign, Floor = height, Zone = zoneNumber })
	local room = group("Zone" .. zoneNumber .. "CornerRefuge", rooms)
	room:SetAttribute("ZoneIndex", zoneNumber)
	-- The room extends 18 studs behind each wall, with an open L-shaped entrance.
	-- An L-shaped floor behind the walls leaves the outgoing ramp unobstructed.
	part(room, "FloorX", Vector3.new(18, 2, 46), Vector3.new(xSign * 84, height - 1, zSign * 70), green)
	part(room, "FloorZ", Vector3.new(28, 2, 18), Vector3.new(xSign * 61, height - 1, zSign * 84), green)
	part(room, "BackWallX", Vector3.new(2, 14, 46), Vector3.new(xSign * 94, height + 7, zSign * 70), darkGreen)
	part(room, "BackWallZ", Vector3.new(46, 14, 2), Vector3.new(xSign * 70, height + 7, zSign * 94), darkGreen)
	part(room, "SideWallX", Vector3.new(2, 14, 20), Vector3.new(xSign * 46, height + 7, zSign * 85), darkGreen)
	part(room, "SideWallZ", Vector3.new(20, 14, 2), Vector3.new(xSign * 85, height + 7, zSign * 46), darkGreen)
	part(room, "Ceiling", Vector3.new(48, 2, 48), Vector3.new(xSign * 70, height + 15, zSign * 70), wallColor)
	local hitbox = part(room, "Hitbox", Vector3.new(46, 14, 46), Vector3.new(xSign * 70, height + 7, zSign * 70), green)
	hitbox.Transparency = 1
	hitbox.CanCollide = false
	hitbox.CastShadow = false
	hitbox:AddTag("SafeZone")
	hitbox:SetAttribute("ZoneIndex", zoneNumber)
	room.PrimaryPart = hitbox

	local signAnchor =
		part(room, "SignAnchor", Vector3.new(0.2, 0.2, 0.2), Vector3.new(xSign * 85, height + 8, zSign * 85), green)
	signAnchor.Transparency = 1
	signAnchor.CanCollide = false
	local gui = Instance.new("BillboardGui")
	gui.Name = "SafeZoneSign"
	gui.Size = UDim2.fromScale(10, 2.6)
	gui.MaxDistance = 95
	gui.AlwaysOnTop = false
	gui.Parent = signAnchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "SAFE"
	label.Font = Enum.Font.GothamBlack
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(193, 255, 107)
	label.Parent = gui
	local stroke = Instance.new("UIStroke")
	stroke.StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize
	stroke.Thickness = 0.06
	stroke.Color = Color3.fromRGB(18, 55, 21)
	stroke.Parent = label
	task.wait()
end

local bottom = height - 8
local function wallStrip(axis, side, along, width, lower, upper, name)
	if upper - lower < 0.01 then
		return
	end
	local center = (upper + lower) / 2
	local size = if axis == "X" then Vector3.new(4, upper - lower, width) else Vector3.new(width, upper - lower, 4)
	local point = if axis == "X" then Vector3.new(side * 77, center, along) else Vector3.new(along, center, side * 77)
	part(shell, name, size, point, wallColor)
end

for _, axis in { "X", "Z" } do
	for _, side in { -1, 1 } do
		wallStrip(axis, side, 0, 94, bottom, 0, axis .. side .. "Middle")
		for _, cornerSign in { -1, 1 } do
			local openings = {}
			for _, alcove in alcoves do
				local wallSide = if axis == "X" then alcove.X else alcove.Z
				local cornerSide = if axis == "X" then alcove.Z else alcove.X
				if wallSide == side and cornerSide == cornerSign then
					table.insert(openings, { alcove.Floor, alcove.Floor + 14 })
				end
			end
			table.sort(openings, function(a, b)
				return a[1] < b[1]
			end)
			local cursor = bottom
			for i, opening in openings do
				wallStrip(
					axis,
					side,
					cornerSign * 61,
					28,
					cursor,
					opening[1],
					axis .. side .. "Corner" .. cornerSign .. "Segment" .. i
				)
				cursor = opening[2]
			end
			wallStrip(axis, side, cornerSign * 61, 28, cursor, 0, axis .. side .. "Corner" .. cornerSign .. "Top")
		end
	end
end
part(shell, "BottomFloor", Vector3.new(150, 3, 150), Vector3.new(0, bottom - 1.5, 0), wallColor)
arena:SetAttribute("SafeZoneTag", "SafeZone")
arena:SetAttribute("SafeZonesRequireGameplayIntegration", true)
arena:SetAttribute("ZoneCount", 6)
arena.Parent = ref
ref.CanCollide = false
ref.CanTouch = false

-- Check the actual wedge collision surface rises at the start and falls at the end.
local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Include
local maxError = 0
for i, wedge in flights do
	params.FilterDescendantsInstances = { wedge }
	local startPoint, endPoint = endpoints[i][1], endpoints[i][2]
	for _, fraction in { 0.03, 0.97 } do
		local expected = startPoint:Lerp(endPoint, fraction)
		local hit = workspace:Raycast(world(expected) + Vector3.new(0, 12, 0), Vector3.new(0, -24, 0), params)
		assert(hit, "Missing ramp surface " .. i)
		maxError = math.max(maxError, math.abs(hit.Position.Y - world(expected).Y))
	end
end
assert(maxError < 0.1, "Wedge orientation mismatch: " .. maxError)
if recording then
	history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return {
	Zones = 6,
	Wedges = #flights,
	SafeZones = #alcoves,
	ZoneDepths = { 16, 48, 88, 136, 192, 256 },
	WedgeHeightError = maxError,
}
