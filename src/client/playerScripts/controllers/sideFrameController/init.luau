-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-- Config
local slideTweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local frameNames = { "Animals", "Eggs" }

-- Sfx
local uiSfx = SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI")
local openSfx = uiSfx:WaitForChild("SideFrameOpen")
local closeSfx = uiSfx:WaitForChild("SideFrameClose")

-- Helper Functions
local function getHiddenPosition(frame: GuiObject, defaultPosition: UDim2)
	local leftEdge = frame.AbsolutePosition.X
	for _, child in frame:GetDescendants() do
		if child:IsA("GuiObject") and child.Visible then
			leftEdge = math.min(leftEdge, child.AbsolutePosition.X)
		end
	end

	local overhang = frame.AbsolutePosition.X - leftEdge
	local offset = frame.AbsoluteSize.X * frame.AnchorPoint.X + overhang + 24
	return UDim2.new(1, offset, defaultPosition.Y.Scale, defaultPosition.Y.Offset)
end

-->
local SideFrameController = knit.CreateController({
	Name = "SideFrameController",
	Frames = {},
	DefaultPositions = {},
	ActiveTweens = {},
	TweenConnections = {},
	ActiveFrame = nil,
})

-- Public Methods
function SideFrameController:Open(frameName: string)
	local frame = self.Frames[frameName]
	if not frame or self.ActiveFrame == frame then
		return
	end

	self.ActiveFrame = frame
	soundHandler:play(openSfx, { Parent = SoundService, PlayOver = true })
	self:slideFrame(self.RightMenu, true)

	for _, other in self.Frames do
		if other ~= frame then
			self:hideFrame(other)
		end
	end

	self:slideFrame(frame, false)
end

function SideFrameController:Close()
	local frame = self.ActiveFrame
	if not frame then
		return
	end

	self.ActiveFrame = nil
	soundHandler:play(closeSfx, { Parent = SoundService, PlayOver = true })
	-- Inside the pit the lava HUD owns the right side, so the menu stays hidden.
	if not knit.GetController("LavaHudController").IsInPit then
		self:slideFrame(self.RightMenu, false)
	end
	self:slideFrame(frame, true)
end

-- Private Methods
function SideFrameController:cancelTween(frame: GuiObject)
	local connection = self.TweenConnections[frame]
	if connection then
		connection:Disconnect()
		self.TweenConnections[frame] = nil
	end

	local tween = self.ActiveTweens[frame]
	if tween then
		self.ActiveTweens[frame] = nil
		tween:Cancel()
		tween:Destroy()
	end
end

function SideFrameController:hideFrame(frame: GuiObject)
	self:cancelTween(frame)

	frame.Visible = false
	frame.Position = getHiddenPosition(frame, self.DefaultPositions[frame])
end

function SideFrameController:slideFrame(frame: GuiObject, isClosing: boolean)
	self:cancelTween(frame)

	local defaultPosition = self.DefaultPositions[frame]
	if not frame.Visible and not isClosing then
		frame.Position = getHiddenPosition(frame, defaultPosition)
	end
	frame.Visible = true

	local target = if isClosing then getHiddenPosition(frame, defaultPosition) else defaultPosition
	local tween = TweenService:Create(frame, slideTweenInfo, { Position = target })
	self.ActiveTweens[frame] = tween

	self.TweenConnections[frame] = tween.Completed:Once(function(playbackState)
		if self.ActiveTweens[frame] ~= tween then
			return
		end

		self.ActiveTweens[frame] = nil
		self.TweenConnections[frame] = nil
		tween:Destroy()

		if isClosing and playbackState == Enum.PlaybackState.Completed then
			frame.Visible = false
		end
	end)

	tween:Play()
end

-- LifeCycle
function SideFrameController:KnitInit()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
	local sideFrames = playerGui:WaitForChild("SideFrames")

	self.RightMenu = playerGui:WaitForChild("Hud"):WaitForChild("RightMenu")
	self.DefaultPositions[self.RightMenu] = self.RightMenu.Position

	for _, name in frameNames do
		local frame = sideFrames:WaitForChild(name)
		self.Frames[name] = frame
		self.DefaultPositions[frame] = frame.Position
		self:hideFrame(frame)
	end

	self.RightMenu.Visible = true
end

return SideFrameController
