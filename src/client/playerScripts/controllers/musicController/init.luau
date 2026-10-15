-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local topbarplus = require(ReplicatedStorage.src.Packages.topbarplus)

-- Config
local musicConfig = require(ReplicatedStorage.src.GameConfiguration.General.musicConfig)

-->
-- Background tracks play in order on a loop. While the player is in the pit they pause and the pit
-- music loops instead; leaving the pit resumes the background track where it stopped.
local MusicController = knit.CreateController({
	Name = "MusicController",
	Config = musicConfig,
	VolumeScale = 1, -- 0 when muted with the topbar button
	IsInPit = false,
	TrackIndex = 1,
	Tweens = {},
})

-- Public Methods
function MusicController:AdjustVolume(number: number)
	self.VolumeScale = number
	self:fade(self:getActiveSound(), self:getTargetVolume(), 0.5)
end

function MusicController:SetInPit(isInPit: boolean)
	if self.IsInPit == isInPit then
		return
	end

	self.IsInPit = isInPit
	local fadeTime = self.Config.FadeTime
	local background = self.Config.SoundTracks[self.TrackIndex]
	local pit = self.Config.PitTrack

	if isInPit then
		self:fade(background, 0, fadeTime, function()
			background:Pause()
		end)
		pit.Volume = 0
		pit.TimePosition = 0
		pit:Play()
		self:fade(pit, self:getTargetVolume(), fadeTime)
	else
		self:fade(pit, 0, fadeTime, function()
			pit:Stop()
		end)
		background.Volume = 0
		if background.TimePosition > 0 then
			background:Resume()
		else
			background:Play()
		end
		self:fade(background, self:getTargetVolume(), fadeTime)
	end
end

-- Private Methods
function MusicController:getTargetVolume(): number
	return self.Config.DefaultVolume * self.VolumeScale
end

function MusicController:getActiveSound(): Sound
	return if self.IsInPit then self.Config.PitTrack else self.Config.SoundTracks[self.TrackIndex]
end

-- Tweens a sound's volume, replacing any fade already running on it.
function MusicController:fade(sound: Sound, volume: number, duration: number, onDone: (() -> ())?)
	local previous = self.Tweens[sound]
	if previous then
		previous:Cancel()
	end

	local tween = TweenService:Create(sound, TweenInfo.new(duration), { Volume = volume })
	self.Tweens[sound] = tween
	tween.Completed:Connect(function(playbackState)
		if playbackState == Enum.PlaybackState.Completed and onDone then
			onDone()
		end
	end)
	tween:Play()
end

function MusicController:playBackgroundTrack(index: number)
	self.TrackIndex = index
	local sound = self.Config.SoundTracks[index]
	sound.Volume = self:getTargetVolume()
	sound.TimePosition = 0
	sound:Play()
end

function MusicController:destroyBackpackButton()
	if not MusicController.topBarBackpackBtn then
		return
	end
	MusicController.topBarBackpackBtn:destroy()
	MusicController.topBarBackpackBtn = nil
end

-- LifeCycle
function MusicController:KnitInit()
	self:destroyBackpackButton()

	self.topBarBackpackBtn = topbarplus
		.new()
		:setName("Music")
		:setImage("rbxassetid://121511542895380", "Deselected")
		:setImage("rbxassetid://117072134589179", "Selected")
		:setImageScale(0.5)
		:setCaption("Toggle Music")
		:bindToggleKey(Enum.KeyCode.M)
		:autoDeselect(false)
		:setOrder(0)

	self.topBarBackpackBtn:select()
	self.topBarBackpackBtn.toggled:Connect(function(isToggled)
		self:AdjustVolume(isToggled and 1 or 0)
	end)

	-- Each background track moves on to the next when it ends (only while it is the one playing).
	local tracks = self.Config.SoundTracks
	for index, sound: Sound in ipairs(tracks) do
		sound.Looped = false
		sound.Ended:Connect(function()
			if not self.IsInPit and self.TrackIndex == index then
				self:playBackgroundTrack(index % #tracks + 1)
			end
		end)
	end
	self.Config.PitTrack.Looped = true
	self:playBackgroundTrack(1)
end

function MusicController:KnitStart()
	knit.GetController("LavaHudController").InPitChanged:Connect(function(isInPit)
		self:SetInPit(isInPit)
	end)
end

return MusicController
