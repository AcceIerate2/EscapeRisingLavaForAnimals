-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local PanelController = knit.CreateController({
	Name = "PanelController",
	TogglePanelSignal = Signal.new(),
	PanelStateChanged = Signal.new(), -- {Visible: boolean, PanelName: string}
	ActivePanel = nil :: string?,
})

-- Public Methods
function PanelController:TogglePanel(panelName: string)
	self.TogglePanelSignal:Fire(panelName)
end

function PanelController:UpdateActivePanel(panelName: string)
	self.ActivePanel = panelName
end

function PanelController:WaitForPanelToClose(panelName: string, timeoutSeconds: number?)
	local hasClosed = false
	local panelStateChangedConnection: RBXScriptConnection? = nil

	local function disconnect()
		if not panelStateChangedConnection then
			return
		end

		panelStateChangedConnection:Disconnect()
		panelStateChangedConnection = nil
	end

	panelStateChangedConnection = self.PanelStateChanged:Connect(function(state: {
		Visible: boolean,
		PanelName: string,
	})
		if state.PanelName ~= panelName or state.Visible then
			return
		end

		hasClosed = true
		disconnect()
	end)

	local startTimeSeconds = os.clock()

	while not hasClosed do
		if timeoutSeconds and (os.clock() - startTimeSeconds) >= timeoutSeconds then
			disconnect()
			return false
		end
		task.wait()
	end
	return true
end

return PanelController
