local Module = {}

function Module:Init(player: Player)
	for _, folder in pairs(script:GetChildren()) do
		for _, moduleScript: ModuleScript in pairs(folder:GetChildren()) do
			local isAModuleScript = moduleScript:IsA("ModuleScript")
			if not isAModuleScript then
				continue
			end
			require(moduleScript):Init(player)
		end
	end
end

return Module
