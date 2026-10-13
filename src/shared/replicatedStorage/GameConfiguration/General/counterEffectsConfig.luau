local CounterEffectsConfig = {}

-- Shared by every counter.
CounterEffectsConfig.Font = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
CounterEffectsConfig.CountTime = 0.35 -- count up/down time when there's no burst
CounterEffectsConfig.Sparkles = 8 -- symbols that burst out of the counter after a gain

-- Icons that pop up around the centre of the screen and arc into the counter on a gain.
CounterEffectsConfig.Burst = {
	MinIcons = 4,
	MaxIcons = 9,
	Cooldown = 0.6, -- gains closer together than this just count up (passive income friendly)
	SpawnArea = Vector2.new(0.3, 0.22), -- fraction of the screen around its centre
	PopTime = 0.22,
	HoldTime = 0.15,
	FlyTime = { Min = 0.45, Max = 0.65 },
	Stagger = 0.05,
}

--[[
	One entry per HUD counter in Hud.Counters (each needs an Icon and a Value).
	DataKey: the player data value it shows.
	Prefix: put before the number ("$" for cash).
	Sparkle: the symbol that bursts out after a gain.
	GainSound / LossSound: paths under SoundService.src.Sfx.
	The flying icons use the counter's own Icon image.
]]
CounterEffectsConfig.Counters = {
	Cash = {
		DataKey = "Cash",
		Prefix = "$",
		Sparkle = "$",
		GainColor = Color3.fromRGB(89, 255, 31),
		LossColor = Color3.fromRGB(255, 63, 69),
		GainSound = "Cash/Gain",
		LossSound = "Cash/Spend",
	},
	Speed = {
		DataKey = "Speed",
		Prefix = "",
		Sparkle = "▲",
		GainColor = Color3.fromRGB(90, 200, 255),
		LossColor = Color3.fromRGB(255, 63, 69),
		GainSound = "Speed/Gain",
		LossSound = "Speed/Loss",
	},
}

return CounterEffectsConfig
