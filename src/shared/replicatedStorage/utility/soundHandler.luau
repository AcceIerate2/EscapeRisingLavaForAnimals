-- Roblox Services
local SoundService = game:GetService("SoundService")

-- Utility
local TypeCheck = require(script.Parent.TypeCheck)

-->
local SoundHandler = {}

function SoundHandler:play(sound: Sound, config: { PlayOver: boolean, Parent: Instance? }?)
	assert(TypeCheck.Instance(sound), "sound arg must be an Instance")

	sound = config and config.PlayOver and sound:Clone() or sound
	sound.Parent = config and TypeCheck.Instance(config.Parent) and config.Parent or SoundService

	sound:Play()
	if config and config.PlayOver then
		sound.Ended:Once(function()
			sound:Destroy()
		end)
	end
end

return SoundHandler
