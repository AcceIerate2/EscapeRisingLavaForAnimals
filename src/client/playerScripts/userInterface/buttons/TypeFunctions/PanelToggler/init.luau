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

local activeTweens: { [GuiObject]: Tween } = {}

local config = {
	[true] = UDim2.fromScale(0.5, 1.25),
	[false] = UDim2.fromScale(0.5, 0.5),
}

local sfx = {
	[true] = nil, -- SoundService:WaitForChild("Sfx"):WaitForChild("UI"):WaitForChild("PanelClose"),
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

local function animate(panel: GuiObject, isClosing: boolean)
	panel.Visible = true

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

	if activeTweens[panel] then
		activeTweens[panel]:Cancel()
		activeTweens[panel] = nil
	end

	local tween = createTween(TweenService, panel, _TweenInfo, {
		Position = config[isClosing],
	})
	activeTweens[panel] = tween

	tween:Play()
	tween.Completed:Once(function()
		tween:Destroy()
		activeTweens[panel] = nil

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
