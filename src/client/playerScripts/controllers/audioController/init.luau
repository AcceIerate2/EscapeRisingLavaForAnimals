-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local AudioController = knit.CreateController({
	Name = "AudioController",
})

-- Public Methods
function AudioController:PlaySound(name: string, playbackConfig: { Parent: Instance, PlayOver: boolean }?)
	assert(typeof(name) == "string", "name arg must be a string")
	assert(typeof(playbackConfig) == "table", "playbackConfig arg must be a table")
	local sound = SoundService:FindFirstChild(name, true)
	if playbackConfig and playbackConfig.PlayOver then
		sound = sound:Clone()
		sound.Parent = playbackConfig.Parent or SoundService
	end
	sound:Play()
end

return AudioController
