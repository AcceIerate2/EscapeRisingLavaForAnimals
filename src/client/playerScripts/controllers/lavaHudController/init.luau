-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local pitArea = require(ReplicatedStorage.src.utility.pitArea)

-- Config
local updateInterval = 0.1 -- seconds between depth bar refreshes
local showOwnHeadshot = true -- TESTING: your own row shows your headshot instead of YOU
local rimMargin = 40 -- studs above the rim that still count as being in the pit (jumping on the top pad)
local pocketReach = 20 -- studs past the pit's footprint that still count as in the pit below the rim (safe zone pockets)
local padMargin = 1 -- studs past a pad's edge that still count as standing on it
local padHeightRange = 10 -- studs above a pad's top that count as standing on it (covers small hops)
local slideTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local slideDistance = 0.25 -- screen widths the right-side menus slide off to the right
local raysSpinTime = 10 -- seconds per turn of the glow behind each action icon
local segmentShade = 0.35 -- how much darker each bar block gets toward its bottom
local segmentGap = 2 -- pixels of black between bar blocks
local surfaceColor = Color3.fromRGB(96, 92, 88) -- block from the rim down to the first zone
local specialColors = {} -- [ZoneId] = ColorSequence, for zones whose block gets a gradient instead of its pad colour

-->
-- While the player is inside the pit, the right side shows the lava actions and the depth bar
-- (zones, every player in the pit, and the lava level) instead of the egg/animal menu.
-- The bar reads GeneratedMap's attributes; the lava level and its type's emoji come from LavaController.
local LavaHudController = knit.CreateController({
	Name = "LavaHudController",
	IsInPit = false,
	InPitChanged = Signal.new(), -- (isInPit: boolean)
	ZoneChanged = Signal.new(), -- (zone: { Name, Id, Depth, Color, Model }?) the zone pad you last landed on
	ZoneList = {},
	LavaMarkers = {}, -- [wave] = ImageLabel
	ActionRequested = Signal.new(), -- (action: string) hook the lava machine and lava products here later
	Avatars = {},
	Thumbnails = {},
})

-- Helper Functions
local function darken(color: Color3): Color3
	return color:Lerp(Color3.new(0, 0, 0), segmentShade)
end

-- Stud overlays tile so that StudsAcross studs fit across the element's width, keeping them square.
local function keepStudsSquare(studs: ImageLabel)
	local function update()
		local size = studs.AbsoluteSize
		if size.X > 0 and size.Y > 0 then
			local across = studs:GetAttribute("StudsAcross")
			studs.TileSize = UDim2.fromScale(1 / across, size.X / across / size.Y)
		end
	end
	studs:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	update()
end

local function watchStuds(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("ImageLabel") and descendant:GetAttribute("StudsAcross") then
			keepStudsSquare(descendant)
		end
	end
	root.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("ImageLabel") and descendant:GetAttribute("StudsAcross") then
			keepStudsSquare(descendant)
		end
	end)
end

-- Public Methods
function LavaHudController:RequestAction(action: string)
	self.ActionRequested:Fire(action)
end

-- Private Methods
-- Depth below the rim as a fraction of the pit's depth, or nil when the position is outside the pit.
function LavaHudController:getDepthFraction(map: Model, position: Vector3): number?
	return pitArea(map, position, rimMargin, pocketReach)
end

-- Slides a right-side menu on or off screen; it is only Visible while on screen or moving.
function LavaHudController:slide(frame: GuiObject, isShown: boolean)
	local shownPosition = self.ShownPositions[frame]
	local goal = if isShown then shownPosition else shownPosition + UDim2.fromScale(slideDistance, 0)

	local previous = self.SlideTweens[frame]
	if previous then
		previous:Cancel()
	end

	frame.Visible = true
	local tween = TweenService:Create(frame, slideTweenInfo, { Position = goal })
	tween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and not isShown then
			frame.Visible = false
		end
	end)
	self.SlideTweens[frame] = tween
	tween:Play()
end

function LavaHudController:setInPit(isInPit: boolean)
	if self.IsInPit == isInPit then
		return
	end

	self.IsInPit = isInPit
	self:slide(self.Root, isInPit)
	self:slide(self.RightMenu, not isInPit)
	if isInPit then
		knit.GetController("SideFrameController"):Close()
	end
	self.InPitChanged:Fire(isInPit)
end

-- The bar is a stack of studded blocks: the surface down to zone 1, then one block per zone running
-- down to the next zone (the last to the floor), so deeper zones get taller blocks.
function LavaHudController:buildZones(map: Model)
	local zones = self.Bar.Zones
	zones:ClearAllChildren()

	local depth = map:GetAttribute("Depth")
	local zonePads = workspace:FindFirstChild("Pads") -- the zone pads (built by hand, not by the map generator)
	if not depth or not zonePads then
		return
	end

	-- Zone models always replicate, but their pads can be streamed out, so read their attributes.
	local list = {}
	for _, zone in zonePads:GetChildren() do
		local zoneDepth = zone:GetAttribute("Depth")
		local platform = zone:FindFirstChild("Platform")
		local color = zone:GetAttribute("Color") or (platform and platform.Color)
		if zoneDepth and color then
			table.insert(list, { Name = zone.Name, Depth = zoneDepth, Color = color, Id = zone:GetAttribute("ZoneId"), Model = zone })
		end
	end
	table.sort(list, function(a, b)
		return a.Depth < b.Depth
	end)
	self.ZoneList = list

	local function addSegment(name: string, top: number, bottom: number, color: ColorSequence)
		local segment = self.Templates.Segment:Clone()
		segment.Name = name
		-- Inset so the bar's black background shows as a border between blocks.
		segment.Position = UDim2.new(0.5, 0, top / depth, segmentGap / 2)
		segment.Size = UDim2.new(1, -segmentGap, (bottom - top) / depth, -segmentGap)
		segment.Shade.Color = color
		segment.Visible = true
		segment.Parent = zones
	end

	if list[1] and list[1].Depth > 0 then
		addSegment("Surface", 0, list[1].Depth, ColorSequence.new(surfaceColor, darken(surfaceColor)))
	end
	for index, zone in list do
		local bottom = if list[index + 1] then list[index + 1].Depth else depth
		addSegment(zone.Name, zone.Depth, bottom, specialColors[zone.Id] or ColorSequence.new(zone.Color, darken(zone.Color)))
	end
end

-- The zone whose pad you're standing on (or just above), if any. Pads that are streamed out are
-- skipped; the one under you is always streamed in.
function LavaHudController:zoneUnder(position: Vector3)
	for _, zone in self.ZoneList do
		local platform = zone.Model:FindFirstChild("Platform")
		if platform then
			local point = platform.CFrame:PointToObjectSpace(position)
			local above = point.Y - platform.Size.Y / 2
			local onTop = math.abs(point.X) <= platform.Size.X / 2 + padMargin and math.abs(point.Z) <= platform.Size.Z / 2 + padMargin
			if onTop and above >= 0 and above <= padHeightRange then
				return zone
			end
		end
	end
	return nil
end

function LavaHudController:setZone(zone)
	-- Compared by name: the zone list is rebuilt when zones stream in.
	local currentName = self.CurrentZone and self.CurrentZone.Name
	if currentName == (zone and zone.Name) then
		return
	end

	self.CurrentZone = zone
	self.ZoneChanged:Fire(zone)
end

function LavaHudController:getAvatar(player: Player): Frame
	local avatar = self.Avatars[player]
	if avatar then
		return avatar
	end

	avatar = self.Templates.Avatar:Clone()
	avatar.Name = player.Name
	avatar.Visible = true
	-- Your own row says YOU; everyone else's shows their headshot.
	local isLocal = player == Players.LocalPlayer and not showOwnHeadshot
	avatar.You.Visible = isLocal
	avatar.Headshot.Visible = not isLocal
	avatar.ZIndex += if isLocal then 2 else 0
	avatar.Parent = self.PlayerMarkers
	self.Avatars[player] = avatar
	if isLocal then
		return avatar
	end

	-- Headshots are fetched once per player and cached.
	local headshot = avatar.Headshot
	local thumbnail = self.Thumbnails[player.UserId]
	if thumbnail then
		headshot.Image = thumbnail
	else
		task.spawn(function()
			local ok, image = pcall(Players.GetUserThumbnailAsync, Players, player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
			if ok and image then
				self.Thumbnails[player.UserId] = image
				if headshot.Parent then
					headshot.Image = image
				end
			end
		end)
	end
	return avatar
end

function LavaHudController:removeAvatar(player: Player)
	local avatar = self.Avatars[player]
	if avatar then
		avatar:Destroy()
		self.Avatars[player] = nil
	end
end

function LavaHudController:update()
	local map = workspace:FindFirstChild("GeneratedMap")
	local zonePads = workspace:FindFirstChild("Pads")
	local zoneCount = zonePads and #zonePads:GetChildren() or 0
	if map ~= self.Map or zoneCount ~= self.ZoneCount then
		self.Map = map
		self.ZoneCount = zoneCount
		if map then
			self:buildZones(map)
		end
	end

	local function fractionOf(player: Player): number?
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		return root and map and self:getDepthFraction(map, root.Position)
	end

	local ownFraction = fractionOf(Players.LocalPlayer)
	self:setInPit(ownFraction ~= nil)

	-- The zone changes only when you land on another zone's pad, and resets when you leave the pit.
	if ownFraction == nil then
		self:setZone(nil)
	else
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local landed = root and self:zoneUnder(root.Position)
		if landed then
			self:setZone(landed)
		end
	end
	if not self.IsInPit then
		return
	end

	-- Everyone in the pit gets an avatar at their depth.
	for _, player in Players:GetPlayers() do
		local fraction = fractionOf(player)
		if fraction then
			self:getAvatar(player).Position = UDim2.fromScale(self.Templates.Avatar.Position.X.Scale, fraction)
		else
			self:removeAvatar(player)
		end
	end

	-- Every rising wave is its type's emoji at its height on the bar.
	local lavaController = knit.GetController("LavaController")
	local depth = map and map:GetAttribute("Depth")
	local seen = {}
	for _, wave in lavaController:GetWaves() do
		local lavaType = lavaController:GetType(wave)
		if depth and lavaType and wave:GetAttribute("StartTime") then
			seen[wave] = true
			local marker = self.LavaMarkers[wave]
			if not marker then
				marker = self.LavaIcon:Clone()
				marker.Name = wave.Name
				marker.Image = lavaType.Emoji
				marker.Visible = true
				marker.Parent = self.Bar
				self.LavaMarkers[wave] = marker
			end
			local fraction = math.clamp(lavaController:GetElevation(wave) / depth, 0, 1)
			marker.Position = UDim2.fromScale(0.5, 1 - fraction)
		end
	end
	for wave, marker in self.LavaMarkers do
		if not seen[wave] then
			marker:Destroy()
			self.LavaMarkers[wave] = nil
		end
	end
end

-- LifeCycle
function LavaHudController:KnitStart()
	task.spawn(function()
		local hud = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Hud")
		self.RightMenu = hud:WaitForChild("RightMenu")
		self.Root = hud:WaitForChild("LavaHud")
		local tracker = self.Root:WaitForChild("DepthTracker")
		self.Bar = tracker:WaitForChild("Bar")
		self.LavaIcon = self.Bar:WaitForChild("LavaIcon") -- template for each wave's marker
		self.LavaIcon.Visible = false
		self.PlayerMarkers = tracker:WaitForChild("Players")
		self.Templates = tracker:WaitForChild("Templates")
		self.ShownPositions = { [self.Root] = self.Root.Position, [self.RightMenu] = self.RightMenu.Position }
		self.SlideTweens = {}
		self.Root.Visible = false
		self.Root.Position = self.Root.Position + UDim2.fromScale(slideDistance, 0)
		watchStuds(self.Root)

		-- The glow behind each action icon turns slowly.
		for _, item in self.Root:WaitForChild("Actions"):GetChildren() do
			local rays = item:FindFirstChild("Rays")
			if rays then
				TweenService:Create(rays, TweenInfo.new(raysSpinTime, Enum.EasingStyle.Linear, Enum.EasingDirection.In, -1), { Rotation = 360 }):Play()
			end
		end

		Players.PlayerRemoving:Connect(function(player)
			self:removeAvatar(player)
		end)

		local elapsed = updateInterval
		RunService.Heartbeat:Connect(function(deltaTime)
			elapsed += deltaTime
			if elapsed >= updateInterval then
				elapsed = 0
				self:update()
			end
		end)
	end)
end

return LavaHudController
