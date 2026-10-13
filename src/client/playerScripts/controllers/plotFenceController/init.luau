-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-- Config
local plotUpgradeConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.plotUpgradeConfig)

-- Essentials
local player = Players.LocalPlayer
local animationConfig = plotUpgradeConfig.Animation
local fenceAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Fences")

-- Helper Functions
-- Pieces are compared by where they actually are and how big they are, since a stretched rail
-- keeps the same pivot as the shorter one it replaces.
local function pieceKey(piece: Instance): string
	local cf, size
	if piece:IsA("Model") then
		cf, size = piece:GetBoundingBox()
	elseif piece:IsA("BasePart") then
		cf, size = piece.CFrame, piece.Size
	else
		return ""
	end
	local p = cf.Position
	return string.format("%.1f,%.1f,%.1f|%.1f,%.1f,%.1f", p.X, p.Y, p.Z, size.X, size.Y, size.Z)
end

local function getPieceKeys(fences: Instance): { [string]: boolean }
	local keys = {}
	for _, piece in fences:GetChildren() do
		keys[pieceKey(piece)] = true
	end
	return keys
end

-->
local PlotFenceController = knit.CreateController({
	Name = "PlotFenceController",
	Plots = {}, -- [plot]: { Level, Keys }
	Watched = setmetatable({}, { __mode = "k" }), -- plots that already have listeners
})

-- Private Methods
function PlotFenceController:playSound()
	if not animationConfig.Sound then
		return
	end

	local sound = SoundService:FindFirstChild("src") and SoundService.src:FindFirstChild("Sfx")
	for _, name in string.split(animationConfig.Sound, "/") do
		sound = sound and sound:FindFirstChild(name)
	end

	if sound and sound:IsA("Sound") then
		soundHandler:play(sound, { Parent = SoundService, PlayOver = true })
	end
end

-- Each part is driven from its own saved home, offset around the piece's real centre (a piece's
-- pivot can sit far from its rails), and put back exactly when done.
function PlotFenceController:animate(fences: Model, oldKeys: { [string]: boolean })
	local gate = fences:GetPivot().Position
	local pieces = {}
	for _, piece in fences:GetChildren() do
		if not (piece:IsA("Model") or piece:IsA("BasePart")) or oldKeys[pieceKey(piece)] then
			continue
		end

		local centre = CFrame.new(if piece:IsA("Model") then piece:GetBoundingBox().Position else piece.Position)
		local parts, homes, offsets = {}, {}, {}
		for _, part in if piece:IsA("BasePart") then { piece } else piece:GetDescendants() do
			if part:IsA("BasePart") then
				table.insert(parts, part)
				table.insert(homes, part.CFrame)
				table.insert(offsets, centre:ToObjectSpace(part.CFrame))
			end
		end

		table.insert(pieces, {
			Centre = centre,
			Parts = parts,
			Homes = homes,
			Offsets = offsets,
			Distance = (centre.Position - gate).Magnitude,
			Tilt = math.rad(math.random(-animationConfig.Tilt, animationConfig.Tilt)),
		})
	end
	if #pieces == 0 then
		return
	end

	table.sort(pieces, function(a, b)
		return a.Distance < b.Distance
	end)
	for index, piece in pieces do
		piece.Delay = math.min((index - 1) * animationConfig.Stagger, animationConfig.MaxStagger)
	end

	local function place(piece, remaining: number)
		-- remaining: 1 = fully underground and tilted, 0 = home (Back easing dips slightly below 0).
		local offset = CFrame.new(0, -animationConfig.Depth * remaining, 0)
			* CFrame.Angles(piece.Tilt * remaining, 0, piece.Tilt * 0.5 * remaining)
		local cframes = table.create(#piece.Parts)
		for i, partOffset in piece.Offsets do
			cframes[i] = piece.Centre * offset * partOffset
		end
		workspace:BulkMoveTo(piece.Parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end

	local function restore()
		for _, piece in pieces do
			workspace:BulkMoveTo(piece.Parts, piece.Homes, Enum.BulkMoveMode.FireCFrameChanged)
		end
	end

	for _, piece in pieces do
		place(piece, 1)
	end

	-- One loop drives every piece; anchored parts moved locally stay where the client puts them.
	local elapsed = 0
	local connection
	connection = RunService.RenderStepped:Connect(function(deltaTime: number)
		if not fences.Parent then
			connection:Disconnect()
			return
		end

		elapsed += deltaTime
		local finished = true

		for _, piece in pieces do
			local alpha = math.clamp((elapsed - piece.Delay) / animationConfig.Duration, 0, 1)
			if alpha < 1 then
				finished = false
			end
			place(piece, 1 - TweenService:GetValue(alpha, Enum.EasingStyle.Back, Enum.EasingDirection.Out))
		end

		if finished then
			connection:Disconnect()
			restore()
		end
	end)
end

-- The new fence can replicate in several batches; animating before it has fully arrived would
-- leave late parts offset. The matching asset in ReplicatedStorage tells us when it's complete.
function PlotFenceController:waitForFences(fences: Model): boolean
	local asset = fenceAssets:FindFirstChild(fences:GetAttribute("FenceAsset") or "")
	if not asset then
		return true
	end

	local expected = #asset:GetDescendants()
	local deadline = os.clock() + 3
	while #fences:GetDescendants() < expected do
		if os.clock() > deadline or not fences.Parent then
			return false
		end
		task.wait()
	end
	return true
end

function PlotFenceController:onFencesAdded(plot: Model, fences: Model)
	local state = self.Plots[plot]
	local level = plot:GetAttribute("PlotLevel") or 1
	local isUpgrade = state and state.Keys and level > (state.Level or 1)
	self.Plots[plot] = { Level = level }

	task.spawn(function()
		local complete = self:waitForFences(fences)
		if not fences.Parent then
			return
		end

		-- Only a real upgrade animates; a plot streaming in or resetting just records its fence.
		if isUpgrade and complete then
			self:animate(fences, state.Keys)
			if plot:GetAttribute("OwnerUserId") == player.UserId then
				self:playSound()
			end
		end

		if self.Plots[plot] and self.Plots[plot].Level == level then
			self.Plots[plot].Keys = getPieceKeys(fences)
		end
	end)
end

function PlotFenceController:watchPlot(plot: Instance)
	if not plot:IsA("Model") then
		return
	end

	local fences = plot:FindFirstChild("Fences")
	self.Plots[plot] = {
		Level = plot:GetAttribute("PlotLevel") or 1,
		Keys = fences and getPieceKeys(fences),
	}

	-- A plot that streams out and back in keeps its listeners.
	if self.Watched[plot] then
		return
	end
	self.Watched[plot] = true

	plot.ChildAdded:Connect(function(child)
		if child.Name == "Fences" and child:IsA("Model") then
			self:onFencesAdded(plot, child)
		end
	end)

	plot.AncestryChanged:Connect(function()
		if not plot:IsDescendantOf(workspace) then
			self.Plots[plot] = nil
		end
	end)
end

-- LifeCycle
function PlotFenceController:KnitStart()
	task.spawn(function()
		local plots = workspace:WaitForChild("Plots")
		plots.ChildAdded:Connect(function(plot)
			self:watchPlot(plot)
		end)
		for _, plot in plots:GetChildren() do
			self:watchPlot(plot)
		end
	end)
end

return PlotFenceController
