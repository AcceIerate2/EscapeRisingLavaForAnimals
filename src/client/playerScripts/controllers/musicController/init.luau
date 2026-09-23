-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local topbarplus = require(ReplicatedStorage.src.Packages.topbarplus)

-- Config
local musicConfig = require(ReplicatedStorage.src.GameConfiguration.General.musicConfig)

-- Helpers
local createTween = TweenService.Create

-->
local MusicController = knit.CreateController({
	Name = "MusicController",
	Config = musicConfig,
})

-- Public Methods
function MusicController:AdjustVolume(number)
	for _, sound: Sound in pairs(self.Config.SoundTracks) do
		local newVolume = self.Config.DefaultVolume * number -- 0.5x, 1x, 0x
		createTween(TweenService, sound, TweenInfo.new(0.5), {
			Volume = newVolume,
		}):Play()
	end
end

-- Private Methods
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

	task.spawn(function()
		while task.wait() do
			for _, sound: Sound in ipairs(self.Config.SoundTracks) do
				sound:Play()
				sound.Ended:Wait()
				task.wait()
			end
		end
	end)
end

return MusicController
