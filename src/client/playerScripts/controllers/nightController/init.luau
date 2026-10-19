-- Roblox Services
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-- Config
local nightConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.nightConfig)

-- Essentials
local player = Players.LocalPlayer

-->
-- Shows the day/night cycle that NightService runs: the corner timer, the big countdown in the middle
-- of the screen at night, the darker lighting, the NightPart popping up over the pit, and the sounds.
local NightController = knit.CreateController({
	Name = "NightController",
	Config = nightConfig,
	Phase = nil,
	LastTick = nil,
})

-- Public Methods
function NightController:IsNight(): boolean
	return self.Phase == "Night"
end

-- Private Methods
function NightController:playSound(path: string)
	local sound = SoundService.src.Sfx
	for _, name in string.split(path, "/") do
		sound = sound and sound:FindFirstChild(name)
	end
	if sound and sound:IsA("Sound") and sound.SoundId ~= "" then
		soundHandler:play(sound, { Parent = SoundService, PlayOver = true })
	end
end

function NightController:timeLeft(): number
	local endsAt = self.State:GetAttribute("EndsAt")
	return if endsAt then endsAt - workspace:GetServerTimeNow() else 0
end

-- The NightPart pops up out of the ground over the pit at night and drops back down at sunrise.
function NightController:animatePart(show: boolean, instant: boolean?)
	local part = workspace:FindFirstChild(nightConfig.PartName)
	if not part or not part:IsA("BasePart") then
		return
	end
	if not self.PartHome then
		self.PartHome = { CFrame = part.CFrame, Size = part.Size }
	end
	local home = self.PartHome
	local flat = Vector3.new(home.Size.X, 0.1, home.Size.Z)
	local flatCFrame = home.CFrame * CFrame.new(0, -home.Size.Y / 2 + 0.05, 0)

	if self.PartTween then
		self.PartTween:Cancel()
	end
	if instant then
		part.Size = if show then home.Size else flat
		part.CFrame = if show then home.CFrame else flatCFrame
		part.Transparency = if show then 0 else 1
		return
	end

	self:playSound(nightConfig.Sounds.Whoosh)
	if show then
		part.Size, part.CFrame = flat, flatCFrame
		part.Transparency = 0
		self.PartTween = TweenService:Create(part, nightConfig.PartAnimation.Show, { Size = home.Size, CFrame = home.CFrame })
	else
		self.PartTween = TweenService:Create(part, nightConfig.PartAnimation.Hide, { Size = flat, CFrame = flatCFrame })
		self.PartTween.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				part.Transparency = 1
			end
		end)
	end
	self.PartTween:Play()
end

function NightController:setLighting(night: boolean, instant: boolean?)
	if not self.DayLighting then
		self.DayLighting = {
			ClockTime = Lighting.ClockTime,
			Brightness = Lighting.Brightness,
			Ambient = Lighting.Ambient,
			OutdoorAmbient = Lighting.OutdoorAmbient,
		}
	end
	local settings = nightConfig.Lighting
	local goal = if night
		then { ClockTime = settings.ClockTime, Brightness = settings.Brightness, Ambient = settings.Ambient, OutdoorAmbient = settings.OutdoorAmbient }
		else self.DayLighting
	if instant then
		for key, value in goal do
			Lighting[key] = value
		end
	else
		TweenService:Create(Lighting, settings.Tween, goal):Play()
	end
end

function NightController:onPhase(phase: string?, instant: boolean)
	if phase == self.Phase then
		return
	end
	local previous = self.Phase
	self.Phase = phase
	local night = phase == "Night"

	self:setLighting(night, instant)
	self:animatePart(night, instant)
	self:showPartCountdown(night)
	-- The corner icon: the sun while counting down to sunrise, the moon while counting down to night.
	self.TimerIcon.Image = if night then nightConfig.SunriseIcon else self.MoonIcon

	-- The night track replaces the music (and follows the music volume and button).
	self.MusicController:SetNight(night)

	if previous ~= nil and not instant then
		if night then
			self:notify(nightConfig.Messages.Night, nightConfig.Messages.NightColor)
		else
			self:notify(nightConfig.Messages.Day, nightConfig.Messages.DayColor)
		end
	end
end

function NightController:notify(message: string, color: Color3)
	self.NotificationController:Push({ Message = message, Color = color })
end

-- The countdowns on the NightPart: every SurfaceGui on it (set up in Studio) with a "Countdown"
-- frame holding a "Seconds" label and a "Moon" image.
function NightController:findPartCountdowns()
	table.clear(self.PartCountdowns)
	local part = workspace:FindFirstChild(nightConfig.PartName)
	for _, gui in if part then part:GetChildren() else {} do
		local frame = gui:IsA("SurfaceGui") and gui:FindFirstChild("Countdown")
		local label = frame and frame:FindFirstChild("Seconds")
		if label then
			local scale = frame:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
			scale.Parent = frame
			local moon = frame:FindFirstChild("Moon")
			gui.Enabled = self.Phase == "Night"
			table.insert(self.PartCountdowns, { Gui = gui, Label = label, Moon = moon, Scale = scale })
		end
	end
end

function NightController:showPartCountdown(visible: boolean)
	for _, countdown in self.PartCountdowns do
		countdown.Gui.Enabled = visible
	end
end

-- Corner timer and the night countdown, plus the tick in the night's last few seconds.
function NightController:updateTimers()
	local left = self:timeLeft()
	local seconds = math.max(0, math.ceil(left))
	local night = self.Phase == "Night"

	-- The icon says which way it's counting (sun = to sunrise, moon = to night).
	self.TimerLabel.Text = `in {nightConfig.FormatTime(left)}`
	-- Red when night is close.
	local warning = not night and left <= nightConfig.Warning.Seconds
	self.TimerLabel.TextColor3 = if warning then nightConfig.Warning.Color else self.TimerColor
	if night then
		local text = `{seconds}s`
		for _, countdown in self.PartCountdowns do
			if countdown.Label.Text ~= text then
				countdown.Label.Text = text
				countdown.Scale.Scale = 1.25
				TweenService:Create(countdown.Scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			end
		end
	end

	-- The tick plays for the night's last few seconds.
	if night and seconds >= 1 and seconds <= nightConfig.CountdownSeconds and self.LastTick ~= seconds then
		self:playSound(nightConfig.Sounds.Countdown)
	end
	self.LastTick = seconds
end

-- LifeCycle
function NightController:KnitInit()
	self.NotificationController = knit.GetController("NotificationController")
	self.MusicController = knit.GetController("MusicController")
end

function NightController:KnitStart()
	task.spawn(function()
		self.State = ReplicatedStorage:WaitForChild("Night")
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("Hud")
		local eventTimer = hud:WaitForChild("EventTimer")
		self.TimerLabel = eventTimer:WaitForChild("Time")
		self.TimerColor = self.TimerLabel.TextColor3
		self.TimerIcon = eventTimer:WaitForChild("NightIcon"):WaitForChild("Moon")
		self.MoonIcon = self.TimerIcon.Image
		self.PartCountdowns = {}
		self:findPartCountdowns()

		-- Join mid-cycle without the pop/whoosh.
		self:onPhase(self.State:GetAttribute("Phase"), true)
		self.State:GetAttributeChangedSignal("Phase"):Connect(function()
			self:onPhase(self.State:GetAttribute("Phase"), false)
		end)
		-- The part can stream in later than the phase arrives.
		workspace.ChildAdded:Connect(function(child)
			if child.Name == nightConfig.PartName then
				self.PartHome = nil
				self:animatePart(self.Phase == "Night", true)
				self:findPartCountdowns()
			end
		end)

		while true do
			self:updateTimers()
			task.wait(0.1)
		end
	end)
end

return NightController
