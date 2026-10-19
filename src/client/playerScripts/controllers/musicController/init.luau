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
-- music loops instead; leaving the pit resumes the background track where it stopped. At night the
-- night track plays over both. Everything here plays through the Music volume (settings + button).
local MusicController = knit.CreateController({
	Name = "MusicController",
	Config = musicConfig,
	VolumeScale = 1, -- 0 when muted with the topbar button
	IsInPit = false,
	IsNight = false,
	TrackIndex = 1,
	Tweens = {},
})

-- Public Methods
function MusicController:AdjustVolume(number: number)
	self.VolumeScale = number
	local sound = self:getActiveSound()
	self:fade(sound, self:getTargetVolume(sound), 0.5)
end

-- At night the night track plays instead of whatever was playing; morning brings that back.
function MusicController:SetNight(isNight: boolean)
	if self.IsNight == isNight then
		return
	end
	self:switchTo(function()
		self.IsNight = isNight
	end)
end

function MusicController:SetInPit(isInPit: boolean)
	if self.IsInPit == isInPit then
		return
	end
	self:switchTo(function()
		self.IsInPit = isInPit
	end)
end

-- Private Methods
-- Volume for a track: the default, the music button, and the track's own boost (if any).
function MusicController:getTargetVolume(sound: Sound?): number
	local boost = if sound == self.Config.NightTrack then self.Config.NightVolumeBoost else 1
	return self.Config.DefaultVolume * self.VolumeScale * boost
end

function MusicController:getActiveSound(): Sound
	if self.IsNight then
		return self.Config.NightTrack
	end
	return if self.IsInPit then self.Config.PitTrack else self.Config.SoundTracks[self.TrackIndex]
end

-- Cross-fades from the sound playing now to the one playing after `change` updates the state.
-- The background tracks pause (and resume where they stopped); the pit and night tracks restart.
function MusicController:switchTo(change: () -> ())
	local fadeTime = self.Config.FadeTime
	local from = self:getActiveSound()
	change()
	local to = self:getActiveSound()
	if from == to then
		return
	end

	local isBackground = table.find(self.Config.SoundTracks, from) ~= nil
	self:fade(from, 0, fadeTime, function()
		if isBackground then
			from:Pause()
		else
			from:Stop()
		end
	end)

	to.Volume = 0
	if table.find(self.Config.SoundTracks, to) and to.TimePosition > 0 then
		to:Resume()
	else
		to.TimePosition = 0
		to:Play()
	end
	self:fade(to, self:getTargetVolume(to), fadeTime)
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
	sound.Volume = self:getTargetVolume(sound)
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
			if not self.IsInPit and not self.IsNight and self.TrackIndex == index then
				self:playBackgroundTrack(index % #tracks + 1)
			end
		end)
	end
	self.Config.PitTrack.Looped = true
	self.Config.NightTrack.Looped = true
	self:playBackgroundTrack(1)
end

function MusicController:KnitStart()
	knit.GetController("LavaHudController").InPitChanged:Connect(function(isInPit)
		self:SetInPit(isInPit)
	end)
end

return MusicController
