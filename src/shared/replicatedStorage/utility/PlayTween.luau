-- Roblox Services
local TweenService = game:GetService("TweenService")

-->
return function(
	instance: Instance,
	tweenInfo: TweenInfo,
	props: { [string]: any },
	functionToCallOnCompletion: () -> ()?
): Tween
	local tween = TweenService:Create(instance, tweenInfo, props)
	tween.Completed:Once(function()
		if typeof(functionToCallOnCompletion) == "function" then
			functionToCallOnCompletion()
		end
		tween:Destroy()
	end)
	tween:Play()
	return tween
end
