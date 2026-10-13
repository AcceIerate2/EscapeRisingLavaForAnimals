-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Config
local plotUpgradeConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.plotUpgradeConfig)

-- Essentials
local player = Players.LocalPlayer

-->
local PlotController = knit.CreateController({
	Name = "PlotController",
	Plot = nil,
	UpgradeConfig = plotUpgradeConfig,
	Signs = {}, -- [plot]: { Gui, Connections }
	SignCount = 0,
})

-- Public Methods
function PlotController:GetPlot(): Model?
	return self.Plot
end

function PlotController:RequestUpgrade()
	self.PlotService
		:UpgradePlot()
		:andThen(function(response)
			if TypeCheck.table(response) and TypeCheck.table(response.NotificationData) then
				self.NotificationController:Push(response.NotificationData)
			end
		end)
		:catch(warn)
end

-- Private Methods
function PlotController:updateOverhead()
	local overhead = self.Plot:WaitForChild("OverheadUI")
	local ui = overhead:WaitForChild("UI")
	local nameLabel = ui:WaitForChild("Name")
	nameLabel.Text = "Your Plot"
end

function PlotController:loadPlot()
	local success, plot = self.PlotService:GetPlot():await()
	assert(success, `[PlotController] Failed to fetch plot: {plot}`)

	-- A remote Instance can arrive as nil before the player's plot has streamed in.
	if not plot then
		local plots = workspace:WaitForChild("Plots", 15)
		assert(plots, "[PlotController] Plots folder did not replicate.")
		local deadline = os.clock() + 15
		repeat
			for _, candidate in ipairs(plots:GetChildren()) do
				if candidate:IsA("Model") and candidate:GetAttribute("OwnerUserId") == player.UserId then
					plot = candidate
					break
				end
			end
			if not plot then
				task.wait(0.1)
			end
		until plot or os.clock() >= deadline
	end

	assert(typeof(plot) == "Instance" and plot:IsA("Model"), "[PlotController] Assigned plot did not replicate.")
	self.Plot = plot
	self:updateOverhead()
end

-- Every owned plot shows its level; only the local player's own sign gets the upgrade button.
function PlotController:refreshSign(plot: Model)
	local sign = self.Signs[plot]
	local gui = sign.Gui

	local ownerId = plot:GetAttribute("OwnerUserId")
	gui.Enabled = ownerId ~= nil
	if not ownerId then
		return
	end

	local level = plot:GetAttribute("PlotLevel") or 1
	local current = self.UpgradeConfig.GetLevel(level)
	local nextLevel = self.UpgradeConfig.Levels[level + 1]
	local isMine = ownerId == player.UserId

	if nextLevel then
		gui.Level.Text = `LV {level}  ▶  LV {level + 1}`
		gui.Slots.Text = `{current.MaxAnimals} ▶ {nextLevel.MaxAnimals} ANIMAL SLOTS`
		gui.Upgrade.Label.Text = `${NumberShortner(nextLevel.Cost)}`
	else
		gui.Level.Text = `LV {level}`
		gui.Slots.Text = `{current.MaxAnimals} ANIMAL SLOTS`
	end

	gui.Upgrade.Visible = isMine and nextLevel ~= nil
	gui.MaxLevel.Visible = nextLevel == nil
end

function PlotController:createSign(plot: Model, template: SurfaceGui)
	self.SignCount += 1
	local gui = template:Clone()
	gui.Name = `PlotSign_{self.SignCount}`
	gui.Parent = player.PlayerGui

	local connections = {}
	for _, attribute in { "OwnerUserId", "PlotLevel" } do
		table.insert(
			connections,
			plot:GetAttributeChangedSignal(attribute):Connect(function()
				self:refreshSign(plot)
			end)
		)
	end

	self.Signs[plot] = { Gui = gui, Connections = connections }
	self.ButtonsController:Link(gui.Upgrade)
	self:refreshSign(plot)
end

function PlotController:removeSign(plot: Model)
	local sign = self.Signs[plot]
	for _, connection in sign.Connections do
		connection:Disconnect()
	end
	self.ButtonsController:Destroy(sign.Gui.Upgrade)
	sign.Gui:Destroy()
	self.Signs[plot] = nil
end

-- Plots stream in and out, so signs are created, re-attached and cleaned up as they come and go.
function PlotController:bindSigns(template: SurfaceGui)
	local plots = workspace:FindFirstChild("Plots")

	for plot in self.Signs do
		if not plot:IsDescendantOf(workspace) then
			self:removeSign(plot)
		end
	end

	for _, plot in if plots then plots:GetChildren() else {} do
		if not plot:IsA("Model") then
			continue
		end

		if not self.Signs[plot] then
			self:createSign(plot, template)
		end

		local signModel = plot:FindFirstChild("PlotUpgradeSign")
		local gui = self.Signs[plot].Gui
		local adornee = signModel and signModel:FindFirstChild("UI")
		if gui.Adornee ~= adornee then
			gui.Adornee = adornee
		end
	end
end

-- LifeCycle
function PlotController:KnitInit()
	self.PlotService = knit.GetService("PlotService")
	self.ButtonsController = knit.GetController("ButtonsController")
	self.NotificationController = knit.GetController("NotificationController")
	self:loadPlot()
end

function PlotController:KnitStart()
	task.spawn(function()
		-- The button system is listening once the UI is ready.
		player:WaitForChild("ClientReady")
		local template = player.PlayerGui:WaitForChild("PlotSignTemplate")

		while true do
			self:bindSigns(template)
			task.wait(1)
		end
	end)
end

return PlotController
