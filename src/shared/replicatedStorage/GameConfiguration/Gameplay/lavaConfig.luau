-- Helpers
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-->
-- Rising lava waves. A new wave spawns at the pit floor every SpawnInterval seconds and climbs to
-- just under the top pad, where it disappears; several can be rising at once. Each wave is a slab
-- (one of the parts in ReplicatedStorage.LavaMutationsParts) that moves up - it never grows.
local LavaConfig = {}

-- Damage
LavaConfig.Damage = 25
LavaConfig.DamageCooldown = 3 -- seconds between hits from the same wave on the same player

-- Waves
LavaConfig.SpawnInterval = 25 -- seconds between new waves
LavaConfig.MaxWaves = 6 -- waves rising at once at most
LavaConfig.TopHoldTime = 0.5 -- seconds a wave stays at the top before disappearing
LavaConfig.FadeTime = 1 -- seconds a finished wave takes to fade out (it no longer damages while fading)
LavaConfig.TopGap = 1 -- studs between a wave's surface and the underside of the top pad

-- Look and sound
LavaConfig.TemplateFolder = "LavaMutationsParts" -- in ReplicatedStorage
LavaConfig.SoundId = "rbxassetid://318794788" -- Lava Bubbling Boiling Loop
LavaConfig.SoundVolume = 0.5
LavaConfig.SoundRollOffMin = 60 -- studs: full volume within this distance of a wave
LavaConfig.SoundRollOffMax = 1000 -- studs: silent beyond this distance

-- Types: rise speed in studs per second. Weight = how often it is picked.
LavaConfig.Types = {
	{ Id = "Calm", Speed = 30, Weight = 30, Color = rgb(115, 205, 40), Emoji = "rbxassetid://88771010531699" },
	{ Id = "Normal", Speed = 40, Weight = 25, Color = rgb(70, 160, 230), Emoji = "rbxassetid://71575164775187" },
	{ Id = "Fast", Speed = 50, Weight = 18, Color = rgb(250, 200, 40), Emoji = "rbxassetid://127252870809377" },
	{ Id = "Furious", Speed = 60, Weight = 12, Color = rgb(255, 130, 30), Emoji = "rbxassetid://83113570687844" },
	{ Id = "Insane", Speed = 70, Weight = 9, Color = rgb(235, 45, 35), Emoji = "rbxassetid://107596500238882" },
	{ Id = "Devil", Speed = 125, Weight = 6, Color = rgb(150, 30, 190), Emoji = "rbxassetid://111554132033727" },
}

-- Mutations: the wave's shape and the part it uses.
--   Full: covers the whole shaft; its part shows the type's emoji and name.
--   Half: covers half the shaft and zig-zags side to side as it rises (ZigZagRise studs per sweep).
--   Hole: covers the shaft except a hole in the middle (HoleFraction of the shaft's width).
LavaConfig.Mutations = {
	{ Id = "Full", Weight = 50, Template = "Full" },
	{ Id = "Half", Weight = 25, Template = "SnakeHalf", ZigZagRise = 120 },
	{ Id = "Hole", Weight = 25, Template = "HoleInMiddleType", HoleFraction = 0.83 },
}

function LavaConfig.GetType(id: string)
	for _, lavaType in LavaConfig.Types do
		if lavaType.Id == id then
			return lavaType
		end
	end
	return nil
end

function LavaConfig.GetMutation(id: string)
	for _, mutation in LavaConfig.Mutations do
		if mutation.Id == id then
			return mutation
		end
	end
	return nil
end

-- A wave's surface height above the pit floor at a server time, from its published attributes.
function LavaConfig.HeightAt(wave, now: number): number
	return math.min(wave.TopHeight, wave.StartHeight + wave.Speed * math.max(0, now - wave.StartTime))
end

-- Where a Half wave sits across the shaft (Z offset of its centre) at a height. A triangle wave
-- driven by height, so pauses and slow-downs keep it in step.
function LavaConfig.HalfOffset(halfExtent: number, height: number): number
	local mutation = LavaConfig.GetMutation("Half")
	local phase = (height / mutation.ZigZagRise) % 2
	return ((if phase < 1 then phase else 2 - phase) - 0.5) * halfExtent
end

-- The areas a wave covers, as rectangles { MinX, MaxX, MinZ, MaxZ } around the shaft's centre.
function LavaConfig.Shape(mutationId: string, halfExtent: number, height: number)
	local H = halfExtent
	if mutationId == "Half" then
		local offset = LavaConfig.HalfOffset(H, height)
		return { { MinX = -H, MaxX = H, MinZ = offset - H / 2, MaxZ = offset + H / 2 } }
	elseif mutationId == "Hole" then
		local h = H * LavaConfig.GetMutation("Hole").HoleFraction
		return {
			{ MinX = -H, MaxX = H, MinZ = h, MaxZ = H },
			{ MinX = -H, MaxX = H, MinZ = -H, MaxZ = -h },
			{ MinX = -H, MaxX = -h, MinZ = -h, MaxZ = h },
			{ MinX = h, MaxX = H, MinZ = -h, MaxZ = h },
		}
	end
	return { { MinX = -H, MaxX = H, MinZ = -H, MaxZ = H } }
end

return LavaConfig
