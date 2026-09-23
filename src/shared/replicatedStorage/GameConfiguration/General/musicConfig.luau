-- Roblox Services
local SoundService = game:GetService("SoundService")

--
local MusicFolder = SoundService:WaitForChild("src"):WaitForChild("Music"):WaitForChild("Background")

-->
local MusicConfig = {}

-- In Order
MusicConfig.SoundTracks = {
	[1] = MusicFolder:WaitForChild("Music1"),
}

MusicConfig.DefaultVolume = 0.35

return MusicConfig
