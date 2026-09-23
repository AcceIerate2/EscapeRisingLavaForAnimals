-- Roblox Services
local Debris = game:GetService("Debris")

-- Utility
local TypeCheck = require(script.Parent.TypeCheck)

-->
local function emit(particleEmitter: ParticleEmitter, parent: Instance)
	if not particleEmitter or not particleEmitter:IsA("ParticleEmitter") then
		return
	end

	local rate = particleEmitter:GetAttribute("Rate")
	if not TypeCheck.number(rate) then
		return
	end
	particleEmitter:Emit(rate)
end

return function(particleContainer: Attachment | Folder | Model | BasePart | ParticleEmitter, parent: Instance)
	assert(TypeCheck.Instance(particleContainer), "particleContainer arg must be an Instance")
	assert(TypeCheck.Instance(parent), "parent arg must be an Instance")

	local clone = particleContainer:Clone()
	clone.Parent = parent

	Debris:AddItem(clone, 5)

	emit(clone :: ParticleEmitter, parent)
	for _, desc in pairs(clone:GetDescendants()) do
		emit(desc, parent)
	end
end
