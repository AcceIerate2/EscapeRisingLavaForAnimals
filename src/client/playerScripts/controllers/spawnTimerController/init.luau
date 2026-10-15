-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local spawnTimerConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.spawnTimerConfig)

-->
-- Shows "<RARITY> Spawns in: MM:SS" above the top pad (PlayerGui.SpawnTimer), from the round that
-- SpawnTimerService publishes on ReplicatedStorage.SpawnTimer.
local SpawnTimerController = knit.CreateController({
	Name = "SpawnTimerController",
})

-- Private Methods
local function formatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	return string.format("%02d:%02d", seconds // 60, seconds % 60)
end

function SpawnTimerController:showRarity()
	local rarity = spawnTimerConfig.GetRarity(self.State:GetAttribute("Rarity") or "")
	if not rarity then
		return
	end

	local label = self.Gui.Row.Rarity
	label.Text = string.upper(rarity.Id)
	local keypoints = {}
	for index, color in rarity.Colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((index - 1) / math.max(#rarity.Colors - 1, 1), color))
	end
	label.Gradient.Color = ColorSequence.new(keypoints)
	task.defer(self.matchTextSize, self)
end

-- Both labels scale to fit their own box; cap them at the smaller size so the line reads as one.
function SpawnTimerController:matchTextSize()
	local row = self.Gui.Row
	local labels = { row.Rarity, row.Time }
	for _, label in labels do
		label.TextLimit.MaxTextSize = 100
	end
	task.wait()

	local size = math.huge
	for _, label in labels do
		if label.TextFits then
			size = math.min(size, label.TextBounds.Y)
		end
	end
	if size < math.huge then
		for _, label in labels do
			label.TextLimit.MaxTextSize = math.max(1, math.floor(size))
		end
	end
end

-- Attaches the billboard to the top pad, waiting for the map to load (and stream in).
function SpawnTimerController:attach()
	local map = workspace:WaitForChild("GeneratedMap")
	local zone = map:WaitForChild("ZonePads"):WaitForChild("Zone1")
	local platform = zone:WaitForChild("Platform")
	self.Gui.Adornee = platform
	self.Gui.StudsOffsetWorldSpace = Vector3.new(0, spawnTimerConfig.Height, 0)
	self.Gui.Enabled = true
end

-- LifeCycle
function SpawnTimerController:KnitStart()
	task.spawn(function()
		self.Gui = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("SpawnTimer")
		self.Gui.Enabled = false
		self.State = ReplicatedStorage:WaitForChild("SpawnTimer")

		self.State:GetAttributeChangedSignal("Rarity"):Connect(function()
			self:showRarity()
		end)
		-- The billboard's pixel size changes with distance, so re-match then too (once per frame at most).
		local pending = false
		self.Gui.Row:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
			if not pending then
				pending = true
				task.defer(function()
					pending = false
					self:matchTextSize()
				end)
			end
		end)
		self:showRarity()
		task.spawn(self.attach, self)

		local timeLabel = self.Gui.Row.Time
		while true do
			local endsAt = self.State:GetAttribute("EndsAt")
			if endsAt then
				timeLabel.Text = `Spawns in: {formatTime(endsAt - workspace:GetServerTimeNow())}`
			end
			task.wait(0.25)
		end
	end)
end

return SpawnTimerController
