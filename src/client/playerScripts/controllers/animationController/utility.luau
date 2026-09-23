-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local Utility = {}

function Utility.AnimationExists(_self, animationName: string)
	assert(TypeCheck.table(_self), "_self arg not passed")
	assert(TypeCheck.string(animationName), "animationName arg must be a string")
	local animationTracks = _self.AnimationTracks
	return TypeCheck.Instance(animationTracks[animationName])
end

return Utility
