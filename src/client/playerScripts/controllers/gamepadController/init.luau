-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local GamepadController = knit.CreateController({
	Name = "GamepadController",
	Connected = UserInputService.GamepadEnabled,

	GamepadIconsChanged = Signal.new(),
	GamepadKeyPressed = Signal.new(),
	Config = require(ReplicatedStorage.src.GameConfiguration.General.gamepadShortcutKeysConfig),
})

-- LifeCycle
function GamepadController:KnitInit()
	UserInputService.GamepadConnected:Connect(function()
		if self.Connected then
			return
		end

		self.Connected = true
		self.GamepadIconsChanged:Fire(true)
	end)

	UserInputService.GamepadDisconnected:Connect(function()
		self.Connected = false
		self.GamepadIconsChanged:Fire(false)
	end)

	UserInputService.InputEnded:Connect(function(inputObject: InputObject, gpe: boolean)
		if gpe then
			return
		end

		local functionToCall = self.Config[inputObject.KeyCode]
		if typeof(functionToCall) == "function" then
			functionToCall()
		end
	end)
end

return GamepadController
