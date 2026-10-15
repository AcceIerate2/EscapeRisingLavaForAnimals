-- Roblox Services
local CollectionService = game:GetService("CollectionService")

-- Essentials
local STUDDED_FACES = { "TopSurface", "FrontSurface", "BackSurface", "LeftSurface", "RightSurface" }
local SPECIAL_PROPS = { Plain = true, Tags = true, Attributes = true, Material = true }

-->
-- Creates parts for the generator. Every CFrame given to it is local to the centre of the pit's
-- floor (Y up, below the Reference), so the whole map follows the Reference's rotation.
local Builder = {}
Builder.__index = Builder

function Builder.new(config, origin: CFrame, rng: Random)
	local self = setmetatable({}, Builder)
	self.Config = config
	self.Origin = origin
	self.Random = rng
	self.PartCount = 0
	self.LapTints = {}

	self.Map = Instance.new("Model")
	self.Map.Name = "GeneratedMap"
	self.Folders = {}
	for _, name in { "Walls", "Structure", "Ramps", "Connections", "ZonePads", "SafeZones" } do
		self.Folders[name] = self:Folder(name, self.Map)
	end
	return self
end

function Builder:Folder(name: string, parent: Instance): Folder
	local existing = parent:FindFirstChild(name)
	if existing then
		return existing
	end

	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

function Builder:Part(className: string, name: string, parent: Instance, localCFrame: CFrame, size: Vector3, color: Color3, props)
	props = props or {}
	local part = Instance.new(className)
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = self.Origin * localCFrame
	part.Color = color
	part.Material = props.Material or self.Config.MaterialPalette.Structure
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth

	-- Classic studs on every visible face of the structure.
	if not props.Plain then
		for _, face in STUDDED_FACES do
			part[face] = Enum.SurfaceType.Studs
		end
		part.BottomSurface = Enum.SurfaceType.Inlet
	end

	for key, value in props do
		if not SPECIAL_PROPS[key] then
			part[key] = value
		end
	end
	for key, value in props.Attributes or {} do
		part:SetAttribute(key, value)
	end
	for _, tag in props.Tags or {} do
		CollectionService:AddTag(part, tag)
	end

	part.Parent = parent
	self.PartCount += 1
	return part
end

-- Invisible, non-colliding helper (spawn markers, regions, hitboxes).
function Builder:Marker(name: string, parent: Instance, localCFrame: CFrame, size: Vector3, props)
	props = props or {}
	props.Plain = true
	props.Transparency = 1
	props.CanCollide = false
	props.CanQuery = false
	props.CastShadow = false
	if props.CanTouch == nil then
		props.CanTouch = false
	end
	return self:Part("Part", name, parent, localCFrame, size, Color3.new(1, 1, 1), props)
end

-- A lap's structure colour. With LapShading on, it fades from Top to Bottom over the top FadeLaps
-- laps (lap numbers count up from the pit floor); otherwise it is `color` with a small, seeded
-- brightness shift per lap.
function Builder:LapColor(color: Color3, lap: number): Color3
	local shading = self.Config.LapShading
	if shading and shading.Enabled then
		local lapsDown = math.max(self.Config.CircuitCount - lap, 0)
		local alpha = math.clamp(lapsDown / math.max(shading.FadeLaps, 1), 0, 1)
		return shading.Top:Lerp(shading.Bottom, alpha)
	end

	if not self.LapTints[lap] then
		self.LapTints[lap] = self.Random:NextNumber(-self.Config.LapTint, self.Config.LapTint)
	end

	local h, s, v = color:ToHSV()
	return Color3.fromHSV(h, s, math.clamp(v + self.LapTints[lap], 0, 1))
end

return Builder
