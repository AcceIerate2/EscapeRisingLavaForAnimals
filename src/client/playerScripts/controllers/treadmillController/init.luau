-- Roblox Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)
local localHide = require(ReplicatedStorage.src.utility.localHide)
local AffordBadge = require(ReplicatedStorage.src.utility.affordBadge)
local SignButtons = require(ReplicatedStorage.src.utility.signButtons)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local Spring = require(ReplicatedStorage.src.utility.Spring)

-- Config
local treadmillConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.treadmillConfig)

-- Essentials
local player = Players.LocalPlayer
local assets = ReplicatedStorage:WaitForChild("Assets")
local fallbackRunAnimation = "rbxassetid://913376220"
local checkInterval = 0.15 -- seconds between "is the player in the treadmill" checks

-->
-- Walking into your own treadmill puts you on its belt and starts training (TreadmillService adds
-- the Speed). Jumping or the Stop button gets you off. While running, boost buttons pop up on screen.
-- Every owned plot's sign (TreadmillUpgradeSign) shows its treadmill; yours unlocks/upgrades it.
local TreadmillController = knit.CreateController({
	Name = "TreadmillController",
	Config = treadmillConfig,
	Running = false,
	BlockedUntil = 0,
	BoostButtons = {}, -- [token] = button
	RunConnections = {},
	Signs = {}, -- [plot] = { Gui, Connections }
	SignCount = 0,
})

-- Public Methods
function TreadmillController:GetLevel(): number
	local level = self.DataController:GetValue("TreadmillLevel")
	return math.clamp(if typeof(level) == "number" then level else 0, 0, treadmillConfig.MaxLevel)
end

function TreadmillController:IsRunning(): boolean
	return self.Running
end

function TreadmillController:RequestUpgrade()
	self.TreadmillService
		:Upgrade()
		:andThen(function(response)
			-- Play the upgrade sound as soon as the server says yes, instead of waiting for the new
			-- model to replicate and be noticed by watch().
			if TypeCheck.table(response) and response.Status then
				self.UpgradeSoundAt = os.clock()
				self:playSound(treadmillConfig.Sounds.Upgrade)
			end
			if TypeCheck.table(response) and TypeCheck.table(response.NotificationData) then
				self.NotificationController:Push(response.NotificationData)
			end
		end)
		:catch(warn)
end

-- Buys the next level with Robux (offered on the sign when the cash price is out of reach).
function TreadmillController:RequestRobuxUpgrade()
	local nextLevel = treadmillConfig.Levels[self:GetLevel() + 1]
	if not nextLevel then
		return
	end
	if nextLevel.ProductId == 0 then
		self.NotificationController:Push({ Message = "Robux upgrades are coming soon!", Color = Color3.new(1, 1, 1) })
		return
	end
	self.MonetizationController:promptPurchase("Product", nextLevel.ProductId)
end

function TreadmillController:ClaimBoost(token: string)
	if not self.BoostButtons[token] then
		return
	end
	self.TreadmillService:ClaimBoost(token):catch(warn)

	-- Feedback happens right away on the click, not when the server answers.
	self:kickFov()
	self.HapticController:Shake(Enum.HapticEffectType.UINotification)
	self:playSound(treadmillConfig.Sounds.Boost)
	local _, root = self:getCharacter()
	local vfx = assets:WaitForChild("Vfx"):FindFirstChild(treadmillConfig.BoostVfx)
	if root and vfx then
		self:emitVfx(vfx, root)
	end

	task.spawn(self.removeBoostButton, self, token, true)
end

function TreadmillController:Stop()
	if not self.Running then
		return
	end
	self:leave(true)
	self.TreadmillService:StopTraining():catch(warn)
end

-- Private Methods
function TreadmillController:getTreadmill(): Model?
	local plot = self.PlotController:GetPlot()
	local treadmill = plot and plot:FindFirstChild("Treadmill")
	return if treadmill and treadmill:IsA("Model") then treadmill else nil
end

function TreadmillController:getCharacter()
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 then
		return nil
	end
	return character, root, humanoid
end

-- Inside the treadmill's box (it has no collision, so players walk into it).
function TreadmillController:isInside(treadmill: Model, root: BasePart): boolean
	local boxCFrame, boxSize = treadmill:GetBoundingBox()
	local point = boxCFrame:PointToObjectSpace(root.Position)
	local half = boxSize / 2
	return math.abs(point.X) <= half.X and math.abs(point.Z) <= half.Z and point.Y <= half.Y + 3
end

function TreadmillController:runAnimationId(character: Model): string
	local animate = character:FindFirstChild("Animate")
	local run = animate and animate:FindFirstChild("run")
	local animation = run and run:FindFirstChildWhichIsA("Animation")
	return if animation and animation.AnimationId ~= "" then animation.AnimationId else fallbackRunAnimation
end

-- Run animation and run sound follow the treadmill's RunSpeed, and speed up while boosted.
function TreadmillController:setAnimationSpeed()
	local boosted = os.clock() < (self.BoostedUntil or 0)
	local speed = treadmillConfig.GetLevel(self:GetLevel()).RunSpeed
	if self.Track then
		self.Track:AdjustSpeed(if boosted then speed * 1.6 else speed)
	end
	if self.RunSound then
		local settings = treadmillConfig.RunSound
		self.RunSound.PlaybackSpeed = settings.Pitch * speed * (if boosted then settings.BoostPitch else 1)
	end

	-- The belt scrolls faster too; the model's own TextureSpeed is the base.
	local treadmill = self:getTreadmill()
	for _, beam in if treadmill then treadmill:GetDescendants() else {} do
		if beam:IsA("Beam") then
			local base = beam:GetAttribute("BaseTextureSpeed")
			if not base then
				base = beam.TextureSpeed
				beam:SetAttribute("BaseTextureSpeed", base)
			end
			beam.TextureSpeed = base * speed * (if boosted then treadmillConfig.Belt.BoostMultiplier else 1)
		end
	end
end

function TreadmillController:startRunSound()
	local sound = self:findSound(treadmillConfig.RunSound.Sound)
	if not sound or sound.SoundId == "" then
		return
	end
	self.RunSound = sound:Clone()
	self.RunSound.Looped = true
	self.RunSound.Parent = SoundService
	self.RunSound:Play()
end

function TreadmillController:stopRunSound()
	local sound = self.RunSound
	self.RunSound = nil
	if not sound then
		return
	end
	local fade = TweenService:Create(sound, TweenInfo.new(treadmillConfig.RunSound.FadeOut), { Volume = 0 })
	fade.Completed:Connect(function()
		sound:Destroy()
	end)
	fade:Play()
end

function TreadmillController:enter(treadmill: Model)
	local character, root, humanoid = self:getCharacter()
	local belt = treadmillConfig.GetBelt(treadmill)
	if self.Running or not character or not belt then
		return
	end
	self.Running = true

	local response = self.TreadmillService:StartTraining():expect()
	if not response.Status or not self.Running or player.Character ~= character then
		self.Running = false
		self.BlockedUntil = os.clock() + treadmillConfig.Placement.RejoinDelay
		return
	end

	-- Held on the belt by constraints (not anchoring) so other players see us there too.
	local height = humanoid.HipHeight + root.Size.Y / 2
	local target = belt * CFrame.new(0, height, 0)
	local attachment = Instance.new("Attachment")
	attachment.Name = "TreadmillAttachment"
	attachment.Parent = root

	local align = Instance.new("AlignPosition")
	align.Mode = Enum.PositionAlignmentMode.OneAttachment
	align.Attachment0 = attachment
	align.RigidityEnabled = true
	align.Position = target.Position
	align.Parent = root

	local orient = Instance.new("AlignOrientation")
	orient.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orient.Attachment0 = attachment
	orient.RigidityEnabled = true
	orient.CFrame = target.Rotation
	orient.Parent = root

	character:PivotTo(target)
	root.AssemblyLinearVelocity = Vector3.zero
	humanoid.AutoRotate = false
	self.Hold = { attachment, align, orient }

	-- Our own run cycle instead of the Animate script's idle.
	local animate = character:FindFirstChild("Animate")
	if animate then
		animate.Enabled = false
	end
	local animator = humanoid:FindFirstChildOfClass("Animator")
	if animator then
		for _, track in animator:GetPlayingAnimationTracks() do
			track:Stop(0.1)
		end
		local animation = Instance.new("Animation")
		animation.AnimationId = self:runAnimationId(character)
		self.Track = animator:LoadAnimation(animation)
		self.Track.Looped = true
		self.Track:Play(0.15)
	end
	self:startRunSound()
	self:setAnimationSpeed()

	-- Jumping gets you off (works for keyboard, gamepad and the touch jump button).
	table.insert(
		self.RunConnections,
		humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
			if humanoid.Jump then
				self:Stop()
			end
		end)
	)
	table.insert(
		self.RunConnections,
		humanoid.Died:Connect(function()
			self:Stop()
		end)
	)

	self.Gui.Stop.Visible = true
end

-- Undoes enter(), and with teleport puts the player next to the belt. The server is told separately.
function TreadmillController:leave(teleport: boolean)
	self.Running = false
	self.BlockedUntil = os.clock() + treadmillConfig.Placement.RejoinDelay
	self.BoostedUntil = 0

	for _, connection in self.RunConnections do
		connection:Disconnect()
	end
	table.clear(self.RunConnections)
	for token in self.BoostButtons do
		self:removeBoostButton(token, false)
	end
	self.Gui.Stop.Visible = false

	if self.Track then
		self.Track:Stop(0.15)
		self.Track:Destroy()
		self.Track = nil
	end
	self:stopRunSound()
	for _, instance in self.Hold or {} do
		instance:Destroy()
	end
	self.Hold = nil

	local character, root, humanoid = self:getCharacter()
	if not character then
		return
	end
	humanoid.AutoRotate = true
	humanoid.Jump = false
	local animate = character:FindFirstChild("Animate")
	if animate then
		animate.Enabled = true
	end

	if not teleport then
		return
	end
	local treadmill = self:getTreadmill()
	if not treadmill then
		return
	end
	local belt = treadmillConfig.GetBelt(treadmill)
	if belt then
		local offset = treadmillConfig.Placement.LeaveOffset + Vector3.new(0, humanoid.HipHeight + root.Size.Y / 2, 0)
		character:PivotTo(belt * CFrame.new(offset))
		root.AssemblyLinearVelocity = Vector3.zero
	end
end

function TreadmillController:showBoostButton(token: string)
	if not self.Running or self.BoostButtons[token] then
		return
	end

	-- The frame pops and wobbles; the button inside it keeps the usual hover/press animation.
	local frame = self.Gui.BoostTemplate:Clone()
	frame.Name = "Boost"
	frame.Position = UDim2.fromScale(math.random(25, 75) / 100, math.random(25, 65) / 100)
	local button = frame.Button
	button.Label.Text = `x{treadmillConfig.Boost.Multiplier}`
	button:SetAttribute("Token", token)
	button:SetAttribute("Type", "Action")
	button:SetAttribute("Action", "ClaimTreadmillBoost")

	local size = frame.Size
	frame.Size = UDim2.fromScale(0, 0)
	frame.Rotation = -6
	frame.Visible = true
	frame.Parent = self.Gui
	self.BoostButtons[token] = frame
	self.ButtonsController:Link(button)
	Spring.target(frame, 0.55, 4, { Size = size })
	TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
		Rotation = 6,
	}):Play()
end

function TreadmillController:removeBoostButton(token: string, claimed: boolean)
	local frame = self.BoostButtons[token]
	if not frame then
		return
	end
	self.BoostButtons[token] = nil
	self.ButtonsController:Unlink(frame.Button)
	frame.Button.Active = false

	-- Clicked: squashes for a beat, then grows and fades out. Unclicked (got off the treadmill): shrinks away.
	Spring.stop(frame)
	local size = frame.Size
	local info = TweenInfo.new(if claimed then 0.175 else 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local grow = if claimed then 1.6 else 0
	if claimed then
		local squash = treadmillConfig.Boost.Click.Squash
		local press = TweenService:Create(frame, TweenInfo.new(0.06, Enum.EasingStyle.Quad), {
			Size = UDim2.fromScale(size.X.Scale * squash, size.Y.Scale * squash),
		})
		press:Play()
		press.Completed:Wait()
		for _, child in frame:GetDescendants() do
			if child:IsA("ImageButton") or child:IsA("ImageLabel") then
				TweenService:Create(child, info, { ImageTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif child:IsA("TextLabel") then
				TweenService:Create(child, info, { TextTransparency = 1, BackgroundTransparency = 1 }):Play()
			elseif child:IsA("UIStroke") then
				TweenService:Create(child, info, { Transparency = 1 }):Play()
			elseif child:IsA("Frame") then
				TweenService:Create(child, info, { BackgroundTransparency = 1 }):Play()
			end
		end
	end
	local tween = TweenService:Create(frame, info, {
		Size = UDim2.fromScale(size.X.Scale * grow, size.Y.Scale * grow),
	})
	tween.Completed:Connect(function()
		frame:Destroy()
	end)
	tween:Play()
end

function TreadmillController:onBoostStarted(duration: number)
	self.BoostedUntil = os.clock() + duration
	self:setAnimationSpeed()
	task.delay(duration, function()
		self:setAnimationSpeed()
	end)
end

-- A quick field-of-view punch so the boost feels like a burst of speed.
function TreadmillController:kickFov()
	local kick = treadmillConfig.Boost.Click.FovKick
	local camera = workspace.CurrentCamera
	if kick == 0 or not camera then
		return
	end
	self.FovBase = self.FovBase or camera.FieldOfView
	local base = self.FovBase
	local out = TweenService:Create(camera, TweenInfo.new(0.08, Enum.EasingStyle.Quad), { FieldOfView = base + kick })
	out.Completed:Once(function()
		local back = TweenService:Create(camera, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
			FieldOfView = base,
		})
		back.Completed:Once(function(state)
			if state == Enum.PlaybackState.Completed then
				self.FovBase = nil
			end
		end)
		back:Play()
	end)
	out:Play()
end

function TreadmillController:findSound(path: string?): Sound?
	local sound = if path then SoundService.src.Sfx else nil
	for _, name in string.split(path or "", "/") do
		sound = sound and sound:FindFirstChild(name)
	end
	return if sound and sound:IsA("Sound") then sound else nil
end

function TreadmillController:playSound(path: string?)
	local sound = self:findSound(path)
	if sound and sound.SoundId ~= "" then
		soundHandler:play(sound, { Parent = SoundService, PlayOver = true })
	end
end

-- Emits every ParticleEmitter in the effect (EmitCount / EmitDelay attributes) from the root.
function TreadmillController:emitVfx(vfx: Instance, root: BasePart)
	local holder = Instance.new("Attachment")
	holder.Name = "TreadmillBoostVfx"
	for _, emitter in vfx:GetDescendants() do
		if emitter:IsA("ParticleEmitter") then
			emitter:Clone().Parent = holder
		end
	end
	holder.Parent = root

	local longest = 0
	for _, emitter in holder:GetChildren() do
		local count = emitter:GetAttribute("EmitCount") or 10
		local delay = emitter:GetAttribute("EmitDelay") or 0
		longest = math.max(longest, delay + emitter.Lifetime.Max)
		task.delay(delay, function()
			if emitter.Parent then
				emitter:Emit(count)
			end
		end)
	end
	Debris:AddItem(holder, longest + 0.5)
end

-- A "+Speed" billboard that flies out of the runner in a random direction and fades.
function TreadmillController:popup(amount: number)
	local _, root = self:getCharacter()
	local template = assets:WaitForChild("Gui"):FindFirstChild(treadmillConfig.Popup.Template)
	if not root or not template then
		return
	end

	local settings = treadmillConfig.Popup
	local gui = template:Clone()
	gui.Group.Amount.Text = `+{NumberShortner(amount)}`
	gui.Adornee = root
	gui.StudsOffsetWorldSpace = settings.Start
	gui.Parent = root

	local spread = settings.Spread
	local target = settings.Start
		+ Vector3.new(
			(math.random() * 2 - 1) * spread.X,
			settings.Rise.Min + math.random() * (settings.Rise.Max - settings.Rise.Min),
			(math.random() * 2 - 1) * spread.Z
		)
	local size = gui.Size
	gui.Size = UDim2.fromScale(size.X.Scale * 0.4, size.Y.Scale * 0.4)

	local lifetime = settings.Lifetime
	-- Flies out over the first half; over the second half it drops down while fading, and is only
	-- removed once fully invisible.
	local rise = TweenService:Create(gui, TweenInfo.new(lifetime * 0.5, Enum.EasingStyle.Quad), { StudsOffsetWorldSpace = target })
	rise.Completed:Once(function()
		TweenService:Create(gui, TweenInfo.new(lifetime * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			StudsOffsetWorldSpace = target - Vector3.new(0, settings.Drop, 0),
		}):Play()
	end)
	rise:Play()
	TweenService:Create(gui, TweenInfo.new(lifetime * 0.3, Enum.EasingStyle.Back), { Size = size }):Play()
	local fade = TweenInfo.new(lifetime * 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, false, lifetime * 0.5)
	local group = gui.Group
	TweenService:Create(group.Amount, fade, { TextTransparency = 1 }):Play()
	TweenService:Create(group.Icon, fade, { ImageTransparency = 1 }):Play()
	for _, stroke in group:GetDescendants() do
		if stroke:IsA("UIStroke") then
			TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		end
	end
	local last = TweenService:Create(group, fade, { GroupTransparency = 1 })
	last.Completed:Once(function()
		gui:Destroy()
	end)
	last:Play()
end

-- Every owned plot's sign shows its treadmill; only your own sign has the unlock/upgrade button.
function TreadmillController:refreshSign(plot: Model)
	local gui = self.Signs[plot].Gui
	local ownerId = plot:GetAttribute("OwnerUserId")
	local level = plot:GetAttribute("TreadmillLevel")
	-- Other players' signs only show while their treadmill is running, like the treadmill itself.
	gui.Enabled = ownerId ~= nil and level ~= nil and (ownerId == player.UserId or self:isRunningOn(plot))
	if not gui.Enabled then
		return
	end

	local nextLevel = treadmillConfig.Levels[level + 1]
	local rate = NumberShortner(treadmillConfig.GetSpeedPerSecond(level))
	if level < 1 then
		gui.Level.Text = "LOCKED"
		gui.Rate.Text = `UNLOCK: {NumberShortner(treadmillConfig.GetSpeedPerSecond(1))} SPEED/S`
	elseif nextLevel then
		gui.Level.Text = `LV {level}  ▶  LV {level + 1}`
		gui.Rate.Text = `{rate} ▶ {NumberShortner(treadmillConfig.GetSpeedPerSecond(level + 1))} SPEED/S`
	else
		gui.Level.Text = `LV {level}`
		gui.Rate.Text = `{rate} SPEED/S`
	end
	if nextLevel then
		gui.Upgrade.Label.Text = `${NumberShortner(nextLevel.Cost)}`
	end

	gui.Upgrade.Visible = ownerId == player.UserId and nextLevel ~= nil
	gui.MaxLevel.Visible = nextLevel == nil
	if ownerId == player.UserId then
		self:refreshMine()
	else
		gui.Robux.Visible = false
	end
end

function TreadmillController:createSign(plot: Model, template: SurfaceGui)
	self.SignCount += 1
	local gui = template:Clone()
	gui.Name = `TreadmillSign_{self.SignCount}`
	gui.Parent = player.PlayerGui

	local connections = {}
	for _, attribute in { "OwnerUserId", "TreadmillLevel" } do
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

function TreadmillController:removeSign(plot: Model)
	local sign = self.Signs[plot]
	for _, connection in sign.Connections do
		connection:Disconnect()
	end
	self.ButtonsController:Destroy(sign.Gui.Upgrade)
	sign.Gui:Destroy()
	self.Signs[plot] = nil
end

-- Plots stream in and out, so signs are created, re-attached and cleaned up as they come and go.
function TreadmillController:bindSigns(template: SurfaceGui)
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

		local signModel = plot:FindFirstChild("TreadmillUpgradeSign")
		local adornee = signModel and signModel:FindFirstChild("UI")
		local gui = self.Signs[plot].Gui
		if gui.Adornee ~= adornee then
			gui.Adornee = adornee
		end

		if plot:GetAttribute("OwnerUserId") == player.UserId and adornee then
			if not self.Badge then
				self.Badge = AffordBadge.new(adornee)
			elseif self.Badge.Gui.Adornee ~= adornee then
				self.Badge:SetAdornee(adornee)
			end
			self:refreshMine()
		end
	end
end

-- Your own sign: the "!" badge while you can afford the next unlock/upgrade, otherwise a red price
-- button with the Robux square next to it.
function TreadmillController:refreshMine()
	local plot = self.PlotController:GetPlot()
	local sign = plot and self.Signs[plot]
	local nextLevel = treadmillConfig.Levels[self:GetLevel() + 1]
	local cash = self.DataController:GetValue("Cash") or 0
	local affordable = nextLevel ~= nil and cash >= nextLevel.Cost

	if self.Badge then
		self.Badge:Show(affordable)
	end
	if sign then
		SignButtons.Set(self.ButtonsController, sign.Gui, affordable or nextLevel == nil)
		SignButtons.SetPrice(sign.Gui, nextLevel and nextLevel.ProductId)
	end
end

-- A new treadmill model after an unlock/upgrade pops in.
function TreadmillController:onTreadmillAdded(treadmill: Model, upgraded: boolean)
	self:setAnimationSpeed()
	if not upgraded then
		return
	end

	treadmill:ScaleTo(0.8)
	Spring.target(treadmill, 0.45, 5, { Scale = 1 })
	-- Upgrades bought with Robux don't go through RequestUpgrade, so their sound plays here.
	if os.clock() - (self.UpgradeSoundAt or 0) > 2 then
		self:playSound(treadmillConfig.Sounds.Upgrade)
	end

	-- Keep running on the new belt: watch() puts the player straight back on.
	if self.Running then
		self:leave(false)
		self.BlockedUntil = 0
	end
end

function TreadmillController:isRunningOn(plot: Model): boolean
	local treadmill = plot:FindFirstChild("Treadmill")
	return treadmill ~= nil and treadmill:GetAttribute("Running") == true
end

-- Other players' treadmills and treadmill signs only show while their owner is running on them.
function TreadmillController:syncOtherTreadmills()
	local plots = workspace:FindFirstChild("Plots")
	for _, plot in if plots then plots:GetChildren() else {} do
		if not plot:IsA("Model") or plot:GetAttribute("OwnerUserId") == player.UserId then
			continue
		end

		local running = self:isRunningOn(plot)
		local treadmill = plot:FindFirstChild("Treadmill")
		if treadmill and treadmill:IsA("Model") then
			localHide.Set(treadmill, not running)
		end
		local sign = plot:FindFirstChild("TreadmillUpgradeSign")
		if sign then
			localHide.Set(sign, not running)
		end
		if self.Signs[plot] and self.Signs[plot].Gui.Enabled ~= (running and plot:GetAttribute("OwnerUserId") ~= nil) then
			self:refreshSign(plot)
		end
	end
end

function TreadmillController:watch()
	local lastTreadmill = nil
	local lastLevel = self:GetLevel()

	while true do
		local treadmill = self:getTreadmill()
		if treadmill ~= lastTreadmill and treadmill then
			local level = treadmill:GetAttribute("Level") or 1
			self:onTreadmillAdded(treadmill, level > lastLevel)
			lastLevel = level
		end
		lastTreadmill = treadmill

		if treadmill and not self.Running and os.clock() >= self.BlockedUntil then
			local character, root = self:getCharacter()
			if character and self:isInside(treadmill, root) then
				self:enter(treadmill)
			end
		end
		task.wait(checkInterval)
	end
end

-- LifeCycle
function TreadmillController:KnitInit()
	self.TreadmillService = knit.GetService("TreadmillService")
	self.DataController = knit.GetController("DataController")
	self.PlotController = knit.GetController("PlotController")
	self.ButtonsController = knit.GetController("ButtonsController")
	self.NotificationController = knit.GetController("NotificationController")
	self.HapticController = knit.GetController("HapticController")
	self.MonetizationController = knit.GetController("MonetizationController")
end

function TreadmillController:KnitStart()
	task.spawn(function()
		-- The button system is listening once the UI is ready.
		player:WaitForChild("ClientReady")
		self.Gui = player.PlayerGui:WaitForChild("Treadmill")
		self.Gui.BoostTemplate.Visible = false
		self.Gui.Stop.Visible = false

		self.DataController:GetValueChangedSignal("TreadmillLevel"):Connect(function()
			self:setAnimationSpeed()
			self:refreshMine()
		end)
		self.DataController:GetValueChangedSignal("Cash"):Connect(function()
			self:refreshMine()
		end)

		-- Speed gained while running flies out of the runner (instead of the HUD counter's effects).
		knit.GetController("CounterDisplayController"):SetQuietCheck("Speed", function()
			return self.Running
		end)
		local lastSpeed = self.DataController:GetValue("Speed") or 0
		self.DataController:GetValueChangedSignal("Speed"):Connect(function()
			local speed = self.DataController:GetValue("Speed") or 0
			if self.Running and speed > lastSpeed then
				self:popup(speed - lastSpeed)
			end
			lastSpeed = speed
		end)

		self.TreadmillService.ShowBoost:Connect(function(token: string)
			self:showBoostButton(token)
		end)
		self.TreadmillService.BoostStarted:Connect(function(duration: number)
			self:onBoostStarted(duration)
		end)
		self.TreadmillService.TrainingStopped:Connect(function()
			if self.Running then
				self:leave(true)
			end
		end)
		player.CharacterAdded:Connect(function()
			if self.Running then
				self:leave(false)
			end
		end)

		local template = player.PlayerGui:WaitForChild("TreadmillSignTemplate")
		task.spawn(function()
			while true do
				self:bindSigns(template)
				task.wait(1)
			end
		end)
		task.spawn(function()
			while true do
				self:syncOtherTreadmills()
				task.wait(0.2)
			end
		end)

		self:watch()
	end)
end

return TreadmillController
