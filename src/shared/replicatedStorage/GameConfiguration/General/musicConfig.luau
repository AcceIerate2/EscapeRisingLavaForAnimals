-- Roblox Services
local SoundService = game:GetService("SoundService")

--
local MusicFolder = SoundService:WaitForChild("src"):WaitForChild("Music"):WaitForChild("Background")
local PitFolder = SoundService:WaitForChild("src"):WaitForChild("Music"):WaitForChild("Pit")
local NightFolder = SoundService:WaitForChild("src"):WaitForChild("Music"):WaitForChild("Night")

-->
local MusicConfig = {}

-- In Order
MusicConfig.SoundTracks = {
	[1] = MusicFolder:WaitForChild("Music1"),
}

-- Loops while the player is in the pit; the background tracks pause until they leave.
MusicConfig.PitTrack = PitFolder:WaitForChild("PitMusic")

-- Loops while it's night (NightController), over both the background and the pit music.
MusicConfig.NightTrack = NightFolder:WaitForChild("NightMusic")
MusicConfig.NightVolumeBoost = 1.5 -- the night track plays this much louder than the other music

MusicConfig.DefaultVolume = 0.35
MusicConfig.FadeTime = 0.8 -- seconds to cross-fade between the background and the pit music

return MusicConfig
