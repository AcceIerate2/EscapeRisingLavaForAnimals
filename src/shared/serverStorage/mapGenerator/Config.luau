-- Helpers
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-->
-- Settings for the procedural shaft map. Values marked (template) were measured from
-- Workspace.TemplateTemplate; change them together if you rescale the map.
-- The shaft is a pit: its top is flush with the Reference's top surface and it goes down from there.
local Config = {}

Config.Seed = 1337
Config.AssetFolder = "MapAssets" -- folder in ServerStorage (outside Rojo's src) with hand-made decoration

-- Shaft
Config.ShaftSize = 126 -- interior width of the square shaft (template: 96); the open middle is ShaftSize - 2 * RampWidth
Config.WallThickness = 2 -- (template) used when FitWallsToReference is off
Config.FitWallsToReference = true -- thicken the walls so the shaft fills the Reference's footprint
Config.WallRim = 0 -- wall height above the Reference's top (0 = flush with the ground)
Config.FloorThickness = 2 -- floor at the very bottom of the pit

-- Route: one ramp per wall, four ramps per lap (template)
Config.RampWidth = 18 -- (template) corridor width; corner landings are RampWidth x RampWidth
Config.RampRise = 25 -- (template) height changed along each wall; one lap = 4 * RampRise
Config.Headroom = 44 -- floor-to-ceiling height of the corridor (template: 20.5)
Config.CircuitCount = 18 -- laps; the pit is CircuitCount * 4 * RampRise deep
Config.MaxSlope = 35 -- degrees, validation limit (template ramps are ~22.6)

-- Zones: a pad floats in the middle of the shaft for each zone, reached by jumping from the ramp.
-- Zone 1 is the shallowest. Deeper zones are smaller pads (a wider jump) and further apart: zones 1
-- and 2 are ZoneFirstSpacing apart, each gap after that grows by the same ratio, and the last pad
-- lands one lap above the pit floor. Depths snap to RampRise, so every pad is level with a landing.
Config.BuildZonePads = false -- the zone pads are hand-built in Workspace.Pads (set true to generate them instead)
Config.ZoneCount = 8
Config.ZoneFirstDepth = 100 -- below the rim
Config.ZoneFirstSpacing = 100
Config.PadSizeTop = 58 -- width of the shallowest pad
Config.PadSizeStep = 2 -- how much narrower each zone deeper is (the gap grows by half this)
Config.MinPadSize = 16 -- validation: pads never shrink below this
Config.PadThickness = 2 -- (template)
Config.PadBorderWidth = 2
Config.PadBorderInset = 1
Config.ZoneHitboxSize = Vector3.new(160, 120, 160) -- (template) spans the lap below the pad and a little above
-- Shallowest first. With the top pad on, Zones[1] is the top pad's zone and the jump pads take the rest.
Config.Zones = {
	{ Id = "Common", Color = rgb(157, 255, 0) },
	{ Id = "Uncommon", Color = rgb(60, 200, 255) },
	{ Id = "Rare", Color = rgb(255, 210, 50) },
	{ Id = "Epic", Color = rgb(215, 70, 255) },
	{ Id = "Legendary", Color = rgb(255, 150, 40) },
	{ Id = "Mythic", Color = rgb(255, 70, 120) },
	{ Id = "Secret", Color = rgb(60, 60, 80) },
	{ Id = "Divine", Color = rgb(255, 245, 190) },
	{ Id = "Celestial", Color = rgb(120, 140, 255) },
}

-- Spawn markers (invisible) on each zone pad
Config.EggSpawnCount = 8
Config.MonsterSpawnCount = 2
Config.SpawnInset = 4 -- studs kept clear from the pad edge
Config.EggSpawnSpacing = 5
Config.MonsterClearance = 12

-- Safe zones: an L-shaped floor in the outside corner of a turn, between the corner landing and
-- the two walls, level with the landing. The walls are pushed out to make room, so the path keeps
-- its full width.
Config.SafeZone = {
	PerLap = 1, -- corners per lap that get one (seeded; never the same corner as the lap below)
	Depth = 12, -- how far the walls are pushed out (the safe zone's width)
	Extent = 12, -- how far it carries on along each wall past the landing
	Height = 36, -- floor-to-ceiling height of the pocket (kept lower than the corridor's Headroom)
	FloorThickness = 2,
	WallThickness = 2, -- the new walls behind it
	MinCover = 20, -- keep it at least this far below the rim, clear of the ground around the pit
	Color = rgb(29, 74, 24),
	Decoration = "SafeZoneDeco", -- model in ServerStorage[AssetFolder] copied into every safe zone
}

-- Pad at the top of the pit, flush with the rim and joined to it by paths. It isn't a rarity
-- zone, so it gets no spawns.
Config.TopPad = {
	Enabled = true,
	Size = 58,
	Color = rgb(9, 137, 207),
	PathWidth = 10,
	Paths = { "West", "East" }, -- walls the paths run to
}

-- One colour for all the structure; LapTint > 0 gives each lap a slightly different shade.
local STRUCTURE_COLOR = rgb(66, 74, 118)
Config.ColorPalette = {
	Wall = STRUCTURE_COLOR,
	Structure = STRUCTURE_COLOR,
	Ramp = STRUCTURE_COLOR,
	Landing = STRUCTURE_COLOR,
	Border = rgb(255, 255, 255),
}
Config.LapTint = 0

-- Laps get darker going down: the top lap is Top, each lap below is a step darker until FadeLaps
-- laps down, and every lap below that is Bottom. Applies to walls, ramps, landings and ceilings.
-- Set Enabled = false to use ColorPalette instead.
Config.LapShading = {
	Enabled = true,
	Top = rgb(103, 99, 102),
	Bottom = rgb(53, 53, 56),
	FadeLaps = 5,
}

Config.MaterialPalette = {
	Structure = Enum.Material.Plastic,
	Platform = Enum.Material.Plastic,
}

return Config
