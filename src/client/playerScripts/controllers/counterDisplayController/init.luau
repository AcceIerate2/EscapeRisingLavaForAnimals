-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-- Config
local config = require(ReplicatedStorage.src.GameConfiguration.General.counterEffectsConfig)

-- Essentials
local player = Players.LocalPlayer
local sfx = SoundService:WaitForChild("src"):WaitForChild("Sfx")

-- Helper Functions
local function bezier(a: Vector2, b: Vector2, c: Vector2, t: number): Vector2
	local u = 1 - t
	return a * (u * u) + b * (2 * u * t) + c * (t * t)
end

local function tween(instance: Instance, seconds: number, goal, style: Enum.EasingStyle?, direction: Enum.EasingDirection?)
	local t = TweenService:Create(
		instance,
		TweenInfo.new(seconds, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out),
		goal
	)
	t:Play()
	return t
end

local function findSound(path: string?): Sound?
	local sound = sfx
	for _, name in string.split(path or "", "/") do
		sound = sound and sound:FindFirstChild(name)
	end
	return if sound and sound:IsA("Sound") then sound else nil
end

local function playSound(sound: Sound?)
	if sound then
		soundHandler:play(sound, { Parent = SoundService, PlayOver = true })
	end
end

-->
local CounterDisplayController = knit.CreateController({
	Name = "CounterDisplayController",
	Counters = {}, -- [name]: counter state
})

-- Private Methods
function CounterDisplayController:format(counter, amount: number): string
	return counter.Settings.Prefix .. NumberShortner(math.floor(amount))
end

function CounterDisplayController:setDisplayed(counter, amount: number)
	counter.Displayed = amount
	counter.Value.Text = self:format(counter, amount)
end

-- Rolls the shown number toward the real value over a time window.
function CounterDisplayController:countTo(counter, target: number, seconds: number)
	if counter.CountConnection then
		counter.CountConnection:Disconnect()
	end

	local from = counter.Displayed
	local elapsed = 0
	counter.CountConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local alpha = math.clamp(elapsed / seconds, 0, 1)
		local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		self:setDisplayed(counter, from + (target - from) * eased)
		if alpha >= 1 then
			counter.CountConnection:Disconnect()
			counter.CountConnection = nil
		end
	end)
end

function CounterDisplayController:pop(counter, scale: number)
	counter.Scale.Scale = scale
	tween(counter.Scale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

function CounterDisplayController:glow(counter)
	local color = counter.Settings.GainColor
	local glow = counter.Value:Clone()
	glow.Name = "Glow"
	glow.ZIndex = counter.Value.ZIndex - 1
	glow.TextColor3 = color
	glow.TextTransparency = 0.35
	for _, child in glow:GetChildren() do
		if child:IsA("UIScale") then
			child:Destroy()
		end
	end
	local outline = glow:FindFirstChildOfClass("UIStroke")
	if outline then
		outline.Color = color
		outline.Thickness *= 5
		outline.Transparency = 0.35
		tween(outline, 0.5, { Transparency = 1 })
	end
	local scale = Instance.new("UIScale")
	scale.Parent = glow
	glow.Parent = counter.Value.Parent

	tween(scale, 0.5, { Scale = 1.25 })
	tween(glow, 0.5, { TextTransparency = 1 }).Completed:Once(function()
		glow:Destroy()
	end)
end

function CounterDisplayController:makeText(text: string, color: Color3, size: number): TextLabel
	local label = Instance.new("TextLabel")
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.BackgroundTransparency = 1
	label.FontFace = config.Font
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Size = UDim2.fromOffset(size * 3, size)
	label.ZIndex = 20

	local outline = Instance.new("UIStroke")
	outline.Color = Color3.new(0, 0, 0)
	outline.Thickness = math.max(size * 0.08, 1.5)
	outline.Parent = label
	return label
end

-- The counter's sparkle symbol bursts out of it and drifts away.
function CounterDisplayController:sparkle(counter)
	local origin = counter.Value.AbsolutePosition - self.Effects.AbsolutePosition
	local size = counter.Value.AbsoluteSize
	local height = size.Y

	for _ = 1, config.Sparkles do
		local start = origin + Vector2.new(math.random() * size.X * 0.7, math.random() * size.Y)
		local direction = Vector2.new(math.random() * 2 - 1, -math.random() - 0.3).Unit
		local distance = height * (0.9 + math.random() * 0.9)

		local symbolSize = height * (0.45 + math.random() * 0.25)
		local sign = self:makeText(counter.Settings.Sparkle, counter.Settings.GainColor, symbolSize)
		sign.Size = UDim2.fromOffset(symbolSize, symbolSize)
		sign.Position = UDim2.fromOffset(start.X, start.Y)
		sign.Rotation = math.random(-30, 30)
		local scale = Instance.new("UIScale")
		scale.Scale = 0.3
		scale.Parent = sign
		sign.Parent = self.Effects

		local life = 0.55 + math.random() * 0.3
		local finish = start + direction * distance
		tween(sign, life, { Position = UDim2.fromOffset(finish.X, finish.Y), Rotation = sign.Rotation + math.random(-90, 90) })
		tween(scale, life * 0.35, { Scale = 1.1 }, Enum.EasingStyle.Back).Completed:Once(function()
			tween(scale, life * 0.65, { Scale = 0 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		end)
		task.delay(life, function()
			sign:Destroy()
		end)
	end
end

-- "+1.5K" rising next to the number, or "-500" dropping away.
function CounterDisplayController:floatAmount(counter, change: number)
	local gained = change > 0
	local height = counter.Value.AbsoluteSize.Y
	local origin = counter.Value.AbsolutePosition - self.Effects.AbsolutePosition

	local label = self:makeText(
		(gained and "+" or "-") .. self:format(counter, math.abs(change)),
		gained and counter.Settings.GainColor or counter.Settings.LossColor,
		height * 0.6
	)
	-- Just right of the number, clear of the counters above and below.
	local width = label.Size.X.Offset
	local start = origin + Vector2.new(counter.Value.TextBounds.X + height * 0.35 + width / 2, height * 0.5)
	label.Position = UDim2.fromOffset(start.X, start.Y)
	label.Parent = self.Effects

	local finish = start + Vector2.new(0, gained and -height * 0.8 or height * 0.8)
	tween(label, 0.9, { Position = UDim2.fromOffset(finish.X, finish.Y) })
	tween(label, 0.9, { TextTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(label.UIStroke, 0.9, { Transparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In).Completed:Once(function()
		label:Destroy()
	end)
end

function CounterDisplayController:landed(counter, isFirst: boolean, isLast: boolean)
	if isFirst then
		playSound(counter.GainSound)
	end
	self:pop(counter, 1.12)
	if isLast then
		self:pop(counter, 1.22)
		self:glow(counter)
		self:sparkle(counter)
	end
end

-- Copies of the counter's icon pop up around the screen centre, then arc into the counter.
function CounterDisplayController:burst(counter, change: number): number
	local burst = config.Burst
	local screen = self.Effects.AbsoluteSize
	local target = (counter.Icon.AbsolutePosition - self.Effects.AbsolutePosition) + counter.Icon.AbsoluteSize / 2
	local iconSize = counter.Icon.AbsoluteSize.Y * 1.15
	local count = math.clamp(math.floor(math.log10(change + 1)) + 2, burst.MinIcons, burst.MaxIcons)

	local arrived = 0
	local lastArrival = 0
	for index = 1, count do
		local delay = (index - 1) * burst.Stagger
		local start = screen / 2
			+ Vector2.new(
				(math.random() * 2 - 1) * screen.X * burst.SpawnArea.X,
				(math.random() * 2 - 1) * screen.Y * burst.SpawnArea.Y
			)
		local flyTime = burst.FlyTime.Min + math.random() * (burst.FlyTime.Max - burst.FlyTime.Min)
		lastArrival = math.max(lastArrival, delay + burst.PopTime + burst.HoldTime + flyTime)

		task.delay(delay, function()
			local icon = Instance.new("ImageLabel")
			icon.AnchorPoint = Vector2.new(0.5, 0.5)
			icon.BackgroundTransparency = 1
			icon.Image = counter.Icon.Image
			icon.Size = UDim2.fromOffset(iconSize, iconSize)
			icon.Position = UDim2.fromOffset(start.X, start.Y)
			icon.Rotation = math.random(-25, 25)
			icon.ZIndex = 15
			local scale = Instance.new("UIScale")
			scale.Scale = 0
			scale.Parent = icon
			icon.Parent = self.Effects

			-- Pop in, hold for a beat, then fly in an arc that curves up and over.
			tween(scale, burst.PopTime, { Scale = 1.15 }, Enum.EasingStyle.Back)
			task.wait(burst.PopTime + burst.HoldTime)

			local control = (start + target) / 2 + Vector2.new((math.random() * 2 - 1) * screen.X * 0.12, -screen.Y * 0.25)
			local startRotation = icon.Rotation
			local spin = math.random(-180, 180)
			local elapsed = 0
			local connection
			connection = RunService.RenderStepped:Connect(function(deltaTime: number)
				elapsed += deltaTime
				local alpha = math.clamp(elapsed / flyTime, 0, 1)
				local eased = TweenService:GetValue(alpha, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local position = bezier(start, control, target, eased)
				icon.Position = UDim2.fromOffset(position.X, position.Y)
				icon.Rotation = startRotation + spin * eased
				scale.Scale = 1.15 - 0.6 * eased

				if alpha >= 1 then
					connection:Disconnect()
					icon:Destroy()
					arrived += 1
					self:landed(counter, arrived == 1, arrived == count)
				end
			end)
		end)
	end

	return lastArrival
end

function CounterDisplayController:lose(counter, change: number)
	playSound(counter.LossSound)
	self:countTo(counter, counter.Current, config.CountTime)
	self:floatAmount(counter, change)

	-- Flash and shake.
	counter.Value.TextColor3 = counter.Settings.LossColor
	tween(counter.Value, 0.45, { TextColor3 = counter.BaseColor })

	if counter.ShakeConnection then
		counter.ShakeConnection:Disconnect()
	end
	local base = counter.BasePosition
	local strength = counter.Value.AbsoluteSize.Y * 0.12
	local elapsed = 0
	counter.ShakeConnection = RunService.RenderStepped:Connect(function(deltaTime: number)
		elapsed += deltaTime
		local decay = math.max(1 - elapsed / 0.35, 0)
		counter.Value.Position = base + UDim2.fromOffset(math.sin(elapsed * 60) * strength * decay, 0)
		counter.Value.Rotation = math.sin(elapsed * 45) * 4 * decay
		if decay <= 0 then
			counter.ShakeConnection:Disconnect()
			counter.ShakeConnection = nil
			counter.Value.Position = base
			counter.Value.Rotation = 0
		end
	end)
end

function CounterDisplayController:onChanged(counter, value: number)
	local change = value - counter.Current
	counter.Current = value
	if change == 0 then
		return
	end

	if change < 0 then
		self:lose(counter, change)
		return
	end

	-- Gains in quick succession (e.g. passive income) skip the burst and just count up.
	local now = os.clock()
	if now - counter.LastBurst < config.Burst.Cooldown then
		self:countTo(counter, value, config.CountTime)
		self:pop(counter, 1.1)
		return
	end
	counter.LastBurst = now

	local duration = self:burst(counter, change)
	self:floatAmount(counter, change)
	-- The number starts rolling as the first icons land and finishes with the last one.
	local firstLanding = config.Burst.PopTime + config.Burst.HoldTime + config.Burst.FlyTime.Min
	task.delay(firstLanding, function()
		self:countTo(counter, counter.Current, math.max(duration - firstLanding, 0.2))
	end)
end

function CounterDisplayController:setupCounter(name: string, settings, frame: Frame)
	local dataController = knit.GetController("DataController")
	local value = frame:WaitForChild("Value")

	-- Grow the number from its left-middle so pops don't push it downward.
	value.AnchorPoint = Vector2.new(0, 0.5)
	value.Position = UDim2.new(value.Position.X.Scale, value.Position.X.Offset, 0.5, 0)
	local scale = Instance.new("UIScale")
	scale.Parent = value

	local counter = {
		Settings = settings,
		Value = value,
		Icon = frame:WaitForChild("Icon"),
		Scale = scale,
		BaseColor = value.TextColor3,
		BasePosition = value.Position,
		GainSound = findSound(settings.GainSound),
		LossSound = findSound(settings.LossSound),
		Current = dataController:GetValue(settings.DataKey),
		Displayed = 0,
		LastBurst = 0,
	}
	self.Counters[name] = counter
	self:setDisplayed(counter, counter.Current)

	dataController:GetValueChangedSignal(settings.DataKey):Connect(function(newValue: number)
		self:onChanged(counter, newValue)
	end)
end

-- LifeCycle
function CounterDisplayController:KnitStart()
	task.spawn(function()
		local hud = player:WaitForChild("PlayerGui"):WaitForChild("Hud")
		local counters = hud:WaitForChild("Counters")

		-- A full-screen layer for flying icons and particles, matching the HUD's coordinate space.
		self.Effects = Instance.new("ScreenGui")
		self.Effects.Name = "CounterEffects"
		self.Effects.ResetOnSpawn = false
		self.Effects.IgnoreGuiInset = hud.IgnoreGuiInset
		self.Effects.ScreenInsets = hud.ScreenInsets
		self.Effects.DisplayOrder = hud.DisplayOrder + 20
		self.Effects.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		self.Effects.Parent = player.PlayerGui

		for name, settings in config.Counters do
			task.spawn(self.setupCounter, self, name, settings, counters:WaitForChild(name))
		end
	end)
end

return CounterDisplayController
