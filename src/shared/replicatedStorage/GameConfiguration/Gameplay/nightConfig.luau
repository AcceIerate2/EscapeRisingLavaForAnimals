-- Helpers
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-->
--[[
	Night time: every DayLength seconds night falls for NightLength seconds. Workspace.NightPart pops up
	over the pit, everyone in the pit is sent to Workspace.SpawnLocation (losing the eggs they carry),
	and when the night ends every egg resets (NightService.EggsReset).
]]
local NightConfig = {}

NightConfig.DayLength = 390 -- seconds of day between nights (6:30)
NightConfig.NightLength = 10 -- seconds a night lasts
NightConfig.PartName = "NightPart" -- in Workspace: covers the pit while it's night
NightConfig.SpawnName = "SpawnLocation" -- in Workspace: where players in the pit are sent at night
NightConfig.SpawnHeight = 3 -- studs above its top surface the character lands
-- Who gets sent home: anyone in the pit (pads, safe zones, ramps - the area the lava HUD shows in),
-- or above it falling or jumping in.
NightConfig.AboveRim = 80 -- studs above the rim that still count
NightConfig.PocketReach = 20 -- studs past the pit's footprint that count below the rim (safe zone pockets)

-- Sounds: paths under SoundService.src.Sfx; an empty SoundId plays nothing. (The night music is
-- Music/Night/NightMusic, played by MusicController.)
NightConfig.Sounds = {
	Whoosh = "Night/Whoosh", -- when the NightPart pops up or drops away
	Countdown = "Night/Countdown", -- each of the last CountdownSeconds of the night
}
NightConfig.CountdownSeconds = 3

-- Messages (rich text) shown when night falls / ends.
NightConfig.Messages = {
	Night = "Night time! The islands are closing - every egg resets at sunrise!",
	Day = "All eggs have reset!",
	NightColor = rgb(120, 200, 255),
	DayColor = rgb(170, 255, 90),
}

-- The NightPart's pop in/out.
NightConfig.PartAnimation = {
	Show = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
	Hide = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In),
}

-- Lighting while it's night (tweened in and back out).
-- Night is mostly the sky going dark; the ground stays bright enough to read.
NightConfig.Lighting = {
	Tween = TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
	ClockTime = 0,
	Brightness = 2,
	Ambient = rgb(128, 128, 140),
	OutdoorAmbient = rgb(120, 120, 136),
}

-- Corner timer icon (Hud.EventTimer.NightIcon.Moon) while it's night (counting to sunrise); the day
-- keeps the icon set in Studio (the moon, counting down to night).
NightConfig.SunriseIcon = "rbxassetid://100106935461236"

-- The corner timer turns this colour once night is this close.
NightConfig.Warning = {
	Seconds = 30,
	Color = rgb(255, 70, 70),
}

-- Corner timer text (Hud.EventTimer.Time).
function NightConfig.FormatTime(seconds: number): string
	seconds = math.max(0, math.ceil(seconds))
	local minutes = seconds // 60
	if minutes > 0 then
		return `{minutes}m {seconds % 60}s`
	end
	return `{seconds}s`
end

return NightConfig
