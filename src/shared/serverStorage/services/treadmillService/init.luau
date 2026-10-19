-- Roblox Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)

-- Config
local treadmillConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.treadmillConfig)

-- Essentials
local treadmillAssets = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Treadmills")

-- Helper Functions
local function failed(message: string)
	return {
		Status = false,
		NotificationData = {
			Message = message,
			Color = Color3.fromRGB(255, 0, 0),
			Sound = SoundService.src.Sfx.NotificationSounds.Decline,
		},
	}
end

-- The marker's bottom face is the ground; models whose pivot isn't at their base are lifted by the gap.
local function standOnMarker(model: Model, marker: BasePart)
	local box, size = model:GetBoundingBox()
	local lift = model:GetPivot().Y - (box.Y - size.Y / 2)
	model:PivotTo(marker.CFrame * CFrame.new(0, -marker.Size.Y / 2 + lift, 0))
end

-->
-- Each player's treadmill sits on their plot (at the plot's TreadmillCFrame) once they unlock it with
-- cash; the plot's TreadmillLevel attribute tells every client what to show on its sign. The client says when
-- its player steps on and off; while they run, the server adds Speed every step and pops up a boost
-- button every so often, which multiplies the gain for a moment when clicked.
local TreadmillService = knit.CreateService({
	Name = "TreadmillService",
	Client = {
		ShowBoost = knit.CreateSignal(), -- (token: string)
		BoostStarted = knit.CreateSignal(), -- (duration: number)
		TrainingStopped = knit.CreateSignal(),
	},
	Config = treadmillConfig,
	Plots = {}, -- [player] = Model
	Treadmills = {}, -- [player] = Model
	Training = {}, -- [player] = { StepElapsed, BoostElapsed, BoostToken, BoostedUntil }
})

-- Client Exposed Methods
function TreadmillService.Client:StartTraining(player: Player)
	return self.Server:StartTraining(player)
end

function TreadmillService.Client:StopTraining(player: Player)
	self.Server:StopTraining(player)
end

function TreadmillService.Client:ClaimBoost(player: Player, token: string)
	return self.Server:ClaimBoost(player, token)
end

function TreadmillService.Client:Upgrade(player: Player)
	return self.Server:Upgrade(player)
end

-- Public Methods
function TreadmillService:GetLevel(player: Player): number
	local level = self.DataService:GetValue(player, "TreadmillLevel")
	return math.clamp(if typeof(level) == "number" then level else 0, 0, treadmillConfig.MaxLevel)
end

function TreadmillService:IsTraining(player: Player): boolean
	return self.Training[player] ~= nil
end

function TreadmillService:Load(player: Player, plot: Model)
	self.Plots[player] = plot
	self:place(player)
end

function TreadmillService:Unload(player: Player)
	self:StopTraining(player)
	local plot = self.Plots[player]
	self.Plots[player] = nil
	if plot then
		plot:SetAttribute("TreadmillLevel", nil)
	end
	local treadmill = self.Treadmills[player]
	self.Treadmills[player] = nil
	if treadmill then
		treadmill:Destroy()
	end
end

function TreadmillService:StartTraining(player: Player)
	if not self.Treadmills[player] then
		return { Status = false }
	end
	if not self:isNearBelt(player) then
		return { Status = false }
	end

	local training = self.Training[player]
	if not training then
		self.Training[player] = { StepElapsed = 0, BoostElapsed = 0 }
		self:markRunning(player)
	elseif training.BoostToken then
		-- Already training (e.g. put back on the belt after an upgrade): the client cleared its boost
		-- button, so show the pending one again or no new one would ever come.
		self.Client.ShowBoost:Fire(player, training.BoostToken)
	end
	return { Status = true }
end

function TreadmillService:StopTraining(player: Player)
	self.Training[player] = nil
	self:markRunning(player)
end

function TreadmillService:ClaimBoost(player: Player, token: string)
	local training = self.Training[player]
	if not training or typeof(token) ~= "string" or training.BoostToken ~= token then
		return { Status = false }
	end

	training.BoostToken = nil
	training.BoostedUntil = os.clock() + treadmillConfig.Boost.Duration
	self.Client.BoostStarted:Fire(player, treadmillConfig.Boost.Duration)
	return { Status = true }
end

function TreadmillService:Upgrade(player: Player)
	if not self.Plots[player] then
		return { Status = false }
	end

	local nextLevel = self:GetLevel(player) + 1
	if nextLevel > treadmillConfig.MaxLevel then
		return failed("Your treadmill is already max level!")
	end

	local cost = treadmillConfig.Levels[nextLevel].Cost
	if not self.CashService:CanAfford(player, cost) then
		local verb = if nextLevel == 1 then "unlock" else "upgrade"
		return failed(`You need ${NumberShortner(cost)} to {verb} your treadmill!`)
	end

	self.CashService:ManipulatePlayerCash(player, -cost, "Addition")
	self:setLevel(player, nextLevel)

	local data = treadmillConfig.Levels[nextLevel]
	return {
		Status = true,
		NotificationData = {
			Message = `{if nextLevel == 1 then "Unlocked" else "Upgraded to"} the {data.Name}! You now train <font color="rgb(90, 200, 255)">{NumberShortner(
				treadmillConfig.GetSpeedPerSecond(nextLevel)
			)} Speed/s</font>.`,
			Color = Color3.fromRGB(255, 255, 255),
			-- No sound: the treadmill's own upgrade sound plays when the new model pops in.
		},
	}
end

-- Private Methods
-- Where the first treadmill's belt sits when it stands on this marker; every level lines up its belt here.
function TreadmillService:referenceBelt(marker: BasePart): Vector3?
	local asset = treadmillAssets:FindFirstChild(treadmillConfig.Levels[1].Model)
	if not asset then
		return nil
	end
	local probe = asset:Clone()
	standOnMarker(probe, marker)
	local belt = treadmillConfig.GetBelt(probe)
	probe:Destroy()
	return belt and belt.Position
end

function TreadmillService:setLevel(player: Player, level: number)
	self.DataService:GetValueObject(player, "TreadmillLevel"):Set(level)
	self:place(player)
end

-- Each level's Robux product buys exactly that level, so it only applies as the very next one.
function TreadmillService:registerProducts()
	for level, data in treadmillConfig.Levels do
		if data.ProductId == 0 then
			continue
		end
		self.MonetizationService.ProductIds[data.ProductId] = function(player: Player)
			if not self.Plots[player] or self:GetLevel(player) + 1 ~= level then
				error("Treadmill level no longer matches this product") -- leaves the receipt unprocessed
			end
			self:setLevel(player, level)
			return true
		end
	end
end

-- Other players only see a treadmill while its owner is running on it (TreadmillController hides it).
function TreadmillService:markRunning(player: Player)
	local treadmill = self.Treadmills[player]
	if treadmill then
		treadmill:SetAttribute("Running", self.Training[player] ~= nil)
	end
end

-- Puts the model for the player's level on their plot, replacing the old one (none while locked).
function TreadmillService:place(player: Player)
	local plot = self.Plots[player]
	local level = self:GetLevel(player)
	plot:SetAttribute("TreadmillLevel", level)
	if level < 1 then
		return
	end

	local marker = plot:FindFirstChild(treadmillConfig.Placement.Marker)
	if not marker or not marker:IsA("BasePart") then
		warn(`[TreadmillService] Plot has no {treadmillConfig.Placement.Marker} part`)
		return
	end

	local asset = treadmillAssets:FindFirstChild(treadmillConfig.GetLevel(level).Model)
	if not asset then
		warn(`[TreadmillService] Missing treadmill asset {treadmillConfig.GetLevel(level).Model}`)
		return
	end

	local treadmill = asset:Clone()
	treadmill.Name = "Treadmill"
	treadmill:SetAttribute("Level", level)
	treadmill:SetAttribute("OwnerUserId", player.UserId)
	treadmill:SetAttribute("Running", self.Training[player] ~= nil)
	-- Streams in whole, so other clients can hide all of it at once.
	treadmill.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	for _, part in treadmill:GetDescendants() do
		if part:IsA("BasePart") then
			-- Players walk into it and get put on the belt by the client.
			part.Anchored = true
			part.CanCollide = false
			part.CanTouch = false
		end
	end
	-- Every model's belt is put exactly where the first treadmill's belt is, so upgrading never moves
	-- the runner (the models' bodies differ a little, their belts don't).
	local beltSpot = self:referenceBelt(marker)
	standOnMarker(treadmill, marker)
	local belt = treadmillConfig.GetBelt(treadmill)
	if belt and beltSpot then
		treadmill:PivotTo(treadmill:GetPivot() + (beltSpot - belt.Position))
	end

	local old = self.Treadmills[player]
	self.Treadmills[player] = treadmill
	treadmill.Parent = plot
	if old then
		old:Destroy()
	end
end

function TreadmillService:isNearBelt(player: Player): boolean
	local treadmill = self.Treadmills[player]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not treadmill or not root or not humanoid or humanoid.Health <= 0 then
		return false
	end

	local belt = treadmillConfig.GetBelt(treadmill)
	return belt ~= nil and (root.Position - belt.Position).Magnitude <= treadmillConfig.Placement.MaxServerDistance
end

function TreadmillService:step(player: Player, training, deltaTime: number)
	local data = treadmillConfig.GetLevel(self:GetLevel(player))
	local boost = treadmillConfig.Boost
	local now = os.clock()

	-- Speed
	training.StepElapsed += deltaTime
	if training.StepElapsed >= data.StepTime then
		training.StepElapsed -= data.StepTime
		-- Boost and the equipped trail multiply each other: x2 boost with a x2 trail = x4.
		local multiplier = (if training.BoostedUntil and now < training.BoostedUntil then boost.Multiplier else 1)
			* self.TrailService:GetSpeedMultiplier(player)
		local speed = self.DataService:GetValueObject(player, "Speed")
		speed:Set(speed:Get() + data.SpeedPerStep * multiplier)
	end

	-- Boost button: stays up until clicked; the next one is counted from the click.
	if not training.BoostToken then
		training.BoostElapsed += deltaTime
		if training.BoostElapsed >= boost.Interval then
			training.BoostElapsed = 0
			training.BoostToken = HttpService:GenerateGUID(false)
			self.Client.ShowBoost:Fire(player, training.BoostToken)
		end
	end
end

-- LifeCycle
function TreadmillService:KnitInit()
	self.DataService = knit.GetService("DataService")
	self.CashService = knit.GetService("CashService")
	self.PlayerService = knit.GetService("PlayerService")
	self.TrailService = knit.GetService("TrailService")
	self.MonetizationService = knit.GetService("MonetizationService")
	self:registerProducts()
end

function TreadmillService:KnitStart()
	self.PlayerService.CharacterAdded:Connect(function(player: Player)
		if self.Training[player] then
			self:StopTraining(player)
			self.Client.TrainingStopped:Fire(player)
		end
	end)

	local checkElapsed = 0
	RunService.Heartbeat:Connect(function(deltaTime: number)
		-- Players who wandered off (or exploited the remote) stop training.
		checkElapsed += deltaTime
		local check = checkElapsed >= 0.5
		if check then
			checkElapsed = 0
		end

		for player, training in self.Training do
			if player.Parent ~= Players or not self.DataService:GetProfile(player) then
				self:StopTraining(player)
				continue
			end
			if check and not self:isNearBelt(player) then
				self:StopTraining(player)
				self.Client.TrainingStopped:Fire(player)
				continue
			end
			self:step(player, training, deltaTime)
		end
	end)
end

return TreadmillService
