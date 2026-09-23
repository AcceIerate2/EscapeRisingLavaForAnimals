-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local utility = require(ReplicatedStorage.src.UIUtility.utility)

-->
local EffectController = knit.CreateController({
	Name = "EffectController",
	Effects = {} :: { [string]: (...any?) -> ...any? },
})

-- Public Methods
function EffectController:PlayEffect(effectName: string, props: { [string]: any })
	local effect = self.Effects[effectName]
	if not TypeCheck.table(effect) then
		return
	end
	effect:Play(utility.createTween, props)
end

function EffectController:EndEffect(effectName: string, props: { [string]: any })
	local effect = self.Effects[effectName]
	if not TypeCheck.table(effect) then
		return
	end

	if typeof(effect["End"]) ~= "function" then
		return
	end
	effect:End(utility.createTween, props)
end

function EffectController:StopEffect(effectName: string)
	local effect = self.Effects[effectName]
	if not TypeCheck.table(effect) then
		return
	end
	if typeof(effect.Stop) == "function" then
		effect:Stop()
	end
end

function EffectController:RequireEffects()
	local children = script.effects:GetChildren()
	for _, moduleScript: ModuleScript in pairs(children) do
		self.Effects[moduleScript.Name] = require(moduleScript)
		if self.Effects[moduleScript.Name].Init then
			self.Effects[moduleScript.Name]:Init()
		end
	end
end

-- LifeCycle
function EffectController:KnitInit()
	self:RequireEffects()
end

return EffectController
