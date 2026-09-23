-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local ButtonsController = knit.CreateController({
	Name = "ButtonsController",

	-- Signals
	IncrementAlertLabelSignal = Signal.new(),
	ClearButtonAlertsSignal = Signal.new(),
	ToggleActionSignal = Signal.new(),
	LinkSignal = Signal.new(),
	UnlinkSignal = Signal.new(),
	DestroyAndUnlinkSignal = Signal.new(),
})

-- Public Methods
function ButtonsController:IncrementButtonAlerts(button, increment)
	self.IncrementAlertLabelSignal:Fire(button, increment)
end

function ButtonsController:ClearButtonAlerts(button)
	self.ClearButtonAlertsSignal:Fire(button)
end

function ButtonsController:ToggleAction(actionName: string, ...)
	self.ToggleActionSignal:Fire(actionName, ... or {})
end

function ButtonsController:Link(button)
	self.LinkSignal:Fire(button)
end

function ButtonsController:Unlink(button)
	self.UnlinkSignal:Fire(button)
end

function ButtonsController:Destroy(button)
	self.DestroyAndUnlinkSignal:Fire(button)
end

return ButtonsController
