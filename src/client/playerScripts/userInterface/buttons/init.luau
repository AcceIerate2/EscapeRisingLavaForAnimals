-- Roblox Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Essentials
local animate = require(script.animate)
local keybinds = require(script.keybinds)
local alerts = require(script.alerts)

-->
local Buttons = {
	ButtonTag = "GuiButton",
	TypeFunctions = {
		Action = require(script.TypeFunctions.Action),
		PanelToggler = require(script.TypeFunctions.PanelToggler),
	},
	Connections = {},
}

function Buttons:destroy(button: GuiButton)
	self:unlink(button)
	if button then
		button:Destroy()
	end
end

function Buttons:unlink(button: GuiButton)
	if not button or not button:IsA("GuiButton") then
		return
	end

	if TypeCheck.RBXScriptConnection(self.Connections[button]) then
		self.Connections[button]:Disconnect()
	end
	self.Connections[button] = nil

	alerts:clear(button)
	animate:disconnect(button)
end

function Buttons:link(button: GuiButton)
	if not button or not button:IsA("GuiButton") then
		warn("button arg must be a GuiButton")
		return
	end

	if TypeCheck.RBXScriptConnection(self.Connections[button]) then
		return
	end

	local buttonType = button:GetAttribute("Type")
	if not TypeCheck.string(buttonType) then
		warn(`{button.Name} does not have a [Type] Attribute`)
		return
	end

	--
	keybinds(button)

	-- animate btn
	animate:connect(button)

	-- link function
	local functionToCall = typeof(self.TypeFunctions[buttonType]) == "function" and self.TypeFunctions[buttonType]
		or self.TypeFunctions[buttonType].Toggle
	if typeof(functionToCall) ~= "function" then
		warn(`[{button.Name}] - Invalid Type [{buttonType}]`)
		return
	end

	-- Connect
	self.Connections[button] = button.Activated:Connect(function()
		alerts:clear(button)
		functionToCall(button, self.Player)
	end)
end

function Buttons:listenToController()
	self.Controller = knit.GetController("ButtonsController")
	self.Controller.IncrementAlertLabelSignal:Connect(function(button, increment)
		alerts:manipulate(button, increment)
	end)

	self.Controller.ClearButtonAlertsSignal:Connect(function(button)
		alerts:clear(button)
	end)

	self.Controller.ToggleActionSignal:Connect(function(actionName, ...)
		self.TypeFunctions.Action(actionName, table.unpack(... or {}))
	end)

	self.Controller.LinkSignal:Connect(function(button)
		self:link(button)
	end)

	self.Controller.UnlinkSignal:Connect(function(button)
		self:unlink(button)
	end)

	self.Controller.DestroyAndUnlinkSignal:Connect(function(button)
		self:destroy(button)
	end)
end

function Buttons:Init(player: Player)
	self.Player = player

	-- load type functions
	local typeFunctionModules = script.TypeFunctions:GetChildren()
	for _, moduleScript: ModuleScript in pairs(typeFunctionModules) do
		local isAModuleScript = moduleScript:IsA("ModuleScript")
		if not isAModuleScript then
			continue
		end
		self.TypeFunctions[moduleScript.Name] = require(moduleScript)
	end

	-- link buttons
	self.PlayerGui = player.PlayerGui
	local buttons = CollectionService:GetTagged("GuiButton")
	for _, button: GuiButton in pairs(buttons) do
		self:link(button)
	end

	-- GamepadController Signals
	knit.GetController("GamepadController").GamepadIconsChanged:Connect(function(enabled: boolean)
		assert(TypeCheck.boolean(enabled), "enabled arg must be a boolean")
		for button: GuiButton, _ in pairs(self.Connections) do
			local gamepadIcon = button:FindFirstChild("GamepadIcon")
			if not gamepadIcon then
				continue
			end
			gamepadIcon.Visible = enabled
		end
	end)

	-- PanelController Signals
	knit.GetController("PanelController").TogglePanelSignal:Connect(self.TypeFunctions.PanelToggler.Toggle)

	-- Listen to ButtonController Signals
	self:listenToController()
end

return Buttons
