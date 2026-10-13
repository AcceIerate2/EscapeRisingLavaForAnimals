-- Roblox Services
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)
local Spring = require(ReplicatedStorage.src.utility.Spring)

-- Essentials
local blur = InstanceCreator("BlurEffect", "Blur", Lighting, {
	Enabled = true,
	Size = 0,
}) :: BlurEffect

-- Helper functions
local createTween = TweenService.Create

-->
local CurrentVisiblePanel = nil
local _TweenInfo = TweenInfo.new(0.15)

local activeAnimations: { [GuiObject]: {} } = {}

local springConfig = {
	OpenDamping = 0.68,
	OpenFrequency = 5.5,
	CloseDamping = 1,
	CloseFrequency = 8,
}

local config = {
	[true] = UDim2.fromScale(0.5, 1.25),
	[false] = UDim2.fromScale(0.5, 0.5),
}

local sfx = {
	[true] = SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI"):WaitForChild("PanelClose"),
	[false] = SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI"):WaitForChild("Panel"),
}

local function playSfx(isCurrentlyVisible: boolean)
	local sfxToPlay: Sound? = sfx[isCurrentlyVisible]
	if not sfxToPlay then
		return
	end
	soundHandler:play(sfxToPlay, {
		Parent = SoundService,
		PlayOver = true,
	})
end

local function toggleFov(isCurrentlyVisible)
	local CameraController = knit.GetController("CameraController")
	if isCurrentlyVisible then
		CameraController:UpdateFov(70, _TweenInfo)
	else
		CameraController:UpdateFov(40, _TweenInfo)
	end
end

local function toggleBlur(isCurrentlyVisible)
	local blurSize = isCurrentlyVisible and 0 or 20
	createTween(TweenService, blur, _TweenInfo, {
		Size = blurSize,
	}):Play()
end

-- Every scrolling list in a panel starts back at the top when it opens.
local function resetScroll(panel: GuiObject)
	for _, descendant in panel:GetDescendants() do
		if descendant:IsA("ScrollingFrame") then
			descendant.CanvasPosition = Vector2.zero
		end
	end
end

local function animate(panel: GuiObject, isClosing: boolean)
	if not panel.Visible and not isClosing then
		panel.Position = config[true]
	end
	panel.Visible = true

	if not isClosing then
		resetScroll(panel)
	end

	if not isClosing and panel.Name == "Parts" then
		soundHandler:play(
			SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI"):WaitForChild("ShopEntrance"),
			{
				Parent = SoundService,
				PlayOver = true,
			}
		)
	end

	toggleFov(isClosing)
	toggleBlur(isClosing)

	local animation = {}
	activeAnimations[panel] = animation

	-- Retarget the spring so rapid toggles keep their current position and momentum.
	Spring.target(
		panel,
		isClosing and springConfig.CloseDamping or springConfig.OpenDamping,
		isClosing and springConfig.CloseFrequency or springConfig.OpenFrequency,
		{
			Position = config[isClosing],
		}
	)

	Spring.completed(panel, function()
		if activeAnimations[panel] ~= animation then
			return
		end
		activeAnimations[panel] = nil

		if isClosing then
			panel.Visible = false
		end
	end)

	playSfx(isClosing)
end

local PanelToggler = {}

function PanelToggler.Toggle(button)
	local panelName = TypeCheck.Instance(button) and button:GetAttribute("PanelName") or button
	if not TypeCheck.string(panelName) then
		return
	end

	local panel = utility.getPanel(panelName)
	if not TypeCheck.Instance(panel) then
		return
	end

	local previous = CurrentVisiblePanel
	local isClosing = (previous == panel)

	CurrentVisiblePanel = if isClosing then nil else panel

	if previous and previous ~= panel then
		animate(previous, true)
	end

	animate(panel, isClosing)

	local panelController = knit.GetController("PanelController")
	panelController:UpdateActivePanel((function()
		if isClosing and panelController.ActivePanel == panelName then
			return nil
		end
		return not isClosing and panelName or nil
	end)())

	panelController.PanelStateChanged:Fire({
		PanelName = panelName,
		Visible = not isClosing,
	})
end

function PanelToggler.GetCurrentVisiblePanel()
	return CurrentVisiblePanel
end

return PanelToggler
