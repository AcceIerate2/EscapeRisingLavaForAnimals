-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local functions = {}

return function(button)
	if not button then
		return
	end

	local actionType = TypeCheck.Instance(button) and button:GetAttribute("Action") or button
	if not TypeCheck.string(actionType) then
		return
	end

	local functionToCall = functions[actionType]
	if typeof(functionToCall) ~= "function" then
		return
	end

	functionToCall(button)
end
