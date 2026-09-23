local Module = {}

local function initModule(player: Player, moduleScript: ModuleScript)
	local isAModuleScript = moduleScript:IsA("ModuleScript")
	if not isAModuleScript then
		return
	end

	local module = require(moduleScript) --:Init(player)
	if typeof(module["Init"]) ~= "function" then
		return
	end

	module:Init(player)
end

function Module:Init(player: Player)
	for _, child in pairs(script:GetChildren()) do
		initModule(player, child)
		for _, moduleScript: ModuleScript in pairs(child:GetChildren()) do
			initModule(player, moduleScript)
		end
	end
end

return Module
