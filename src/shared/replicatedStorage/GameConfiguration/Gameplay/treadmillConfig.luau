local TreadmillConfig = {}

--[[
	One entry per treadmill level, in order. Players start at level 0 (no treadmill) and unlock
	level 1 with cash.
	Model: model in ReplicatedStorage.Assets.Treadmills placed on the plot at TreadmillCFrame.
	Cost: cash to unlock / upgrade TO this level.
	ProductId: Developer Product that buys this level with Robux (shown on the sign when the player
	can't afford the cash price). 0 = not set up yet ("coming soon").
	SpeedPerStep: Speed gained every StepTime seconds of running.
	RunSpeed: how fast the run animation plays (1 = normal).

	Progression: each treadmill trains roughly 3x faster than the one before (Speed per second),
	and each upgrade from level 2 on costs roughly 22x the one before.
	  Lv1 5/s · Lv2 ~14/s · Lv3 ~47/s · Lv4 144/s · Lv5 ~432/s · Lv6 1.3K/s
]]
TreadmillConfig.Levels = {
	{
		Model = "NormalTreadmill",
		Name = "Normal Treadmill",
		Cost = 500,
		ProductId = 0,
		SpeedPerStep = 2,
		StepTime = 0.4,
		RunSpeed = 1,
	},
	{
		Model = "ForestTreadmill",
		Name = "Forest Treadmill",
		Cost = 12_500,
		ProductId = 0,
		SpeedPerStep = 5,
		StepTime = 0.35,
		RunSpeed = 1.25,
	},
	{
		Model = "HackerTreadmill",
		Name = "Hacker Treadmill",
		Cost = 275_000,
		ProductId = 0,
		SpeedPerStep = 14,
		StepTime = 0.3,
		RunSpeed = 1.45,
	},
	{
		Model = "TreadmillToxic",
		Name = "Toxic Treadmill",
		Cost = 6_000_000,
		ProductId = 0,
		SpeedPerStep = 36,
		StepTime = 0.25,
		RunSpeed = 1.65,
	},
	{
		Model = "TreadmillFrozen",
		Name = "Frozen Treadmill",
		Cost = 135_000_000,
		ProductId = 0,
		SpeedPerStep = 95,
		StepTime = 0.22,
		RunSpeed = 1.85,
	},
	{
		Model = "LavaTreadmill",
		Name = "Lava Treadmill",
		Cost = 3_000_000_000,
		ProductId = 0,
		SpeedPerStep = 260,
		StepTime = 0.2,
		RunSpeed = 2.05,
	},
}

TreadmillConfig.MaxLevel = #TreadmillConfig.Levels

-- The boost button pops up while running; clicking it multiplies Speed gain for a moment.
TreadmillConfig.Boost = {
	Interval = 3, -- seconds of running after a boost is clicked before the next button pops up
	Multiplier = 2, -- Speed gain multiplier while boosted
	Duration = 1, -- seconds a boost lasts

	-- Click feedback (all instant, before the server answers).
	Click = {
		Squash = 0.85, -- the button squashes to this size for a beat before it bursts
		FovKick = 6, -- degrees the camera zooms out for a moment (0 = off)
	},
}

TreadmillConfig.Placement = {
	Marker = "TreadmillCFrame", -- part in each plot the treadmill is placed on
	-- Where the player is put when they get off, from the belt's middle: X = to the runner's right
	-- (negative = left), Z = behind them (negative = in front).
	LeaveOffset = Vector3.new(-7, 0, 0),
	RejoinDelay = 1.25, -- seconds before stepping back in starts running again
	JumpBackDelay = 0.4, -- seconds after getting off before jumping works again (so the jump that got you off doesn't fire)
	MaxServerDistance = 15, -- studs from the belt the server still accepts training from
}

-- Paths under SoundService.src.Sfx, played for the local player; nil for none.
TreadmillConfig.Sounds = {
	Upgrade = "Treadmill/Upgrade", -- unlocking or upgrading the treadmill
	Boost = "Treadmill/Boost", -- clicking a boost button
}

-- The belt's scrolling Beam(s) in the model: TextureSpeed = the model's own TextureSpeed * the level's
-- RunSpeed (* BoostMultiplier while boosted).
TreadmillConfig.Belt = {
	BoostMultiplier = 1.6,
}

-- The belt's looping run sound while you train. It plays faster on faster treadmills:
-- PlaybackSpeed = Pitch * the level's RunSpeed (* BoostPitch while boosted).
TreadmillConfig.RunSound = {
	Sound = "Treadmill/Run", -- path under SoundService.src.Sfx
	Pitch = 1,
	BoostPitch = 1.2,
	FadeOut = 0.2, -- seconds it fades out when you get off
}

-- The aura on the runner's body when they click a boost: a character model in ReplicatedStorage.Assets.Vfx
-- whose limbs (R6 names) hold the effects; each limb's effects go on the same limb of the player.
TreadmillConfig.BoostAura = {
	Model = "DiamondBoost",
	Duration = 1, -- seconds the aura stays on (its particles then fade out on their own)
	BeamFadeTime = 0.5, -- seconds its beams take to fade out after that
	-- R6 limb -> the R15 part it goes on, for R15 bodies.
	R15Limbs = {
		Torso = "UpperTorso",
		["Left Arm"] = "LeftLowerArm",
		["Right Arm"] = "RightLowerArm",
		["Left Leg"] = "LeftLowerLeg",
		["Right Leg"] = "RightLowerLeg",
	},
}

-- "+Speed" popups that fly out of the runner every step (ReplicatedStorage.Assets.Gui.SpeedPopup).
TreadmillConfig.Popup = {
	Template = "SpeedPopup",
	Lifetime = 0.8, -- seconds each popup flies before it's gone
	Start = Vector3.new(0, 0, 0), -- studs from the root (HumanoidRootPart) it starts at
	Spread = Vector3.new(4, 0, 2), -- random +/- studs it flies sideways (X) and forward/back (Z)
	Rise = NumberRange.new(2, 4.5), -- random studs it flies up
	Drop = 1.5, -- studs it falls back down while fading out
}

-- Public Methods
function TreadmillConfig.GetLevel(level: number)
	return TreadmillConfig.Levels[math.clamp(level, 1, TreadmillConfig.MaxLevel)]
end

-- The belt of a placed treadmill model, from its Beam (which scrolls from Attachment0 to Attachment1):
-- a CFrame on the belt's surface at its middle, facing the way the runner faces, and its length.
function TreadmillConfig.GetBelt(model: Model): (CFrame?, number)
	local beam = model:FindFirstChildWhichIsA("Beam", true)
	local from, to = beam and beam.Attachment0, beam and beam.Attachment1
	if not from or not to then
		return nil, 0
	end

	local a, b = from.WorldPosition, to.WorldPosition
	local flat = Vector3.new(a.X - b.X, 0, a.Z - b.Z)
	if flat.Magnitude < 1e-3 then
		return nil, 0
	end
	local middle = (a + b) / 2
	return CFrame.lookAt(middle, middle + flat), flat.Magnitude
end

-- Speed per second at a level, for UI.
function TreadmillConfig.GetSpeedPerSecond(level: number): number
	if level < 1 then
		return 0
	end
	local data = TreadmillConfig.GetLevel(level)
	return data.SpeedPerStep / data.StepTime
end

return TreadmillConfig
