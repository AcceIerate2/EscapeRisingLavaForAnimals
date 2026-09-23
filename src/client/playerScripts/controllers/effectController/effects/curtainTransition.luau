-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-- Essentials
local player = Players.LocalPlayer
local playerGui = player.PlayerGui

-- Sfx
local thudSfx = SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("General"):WaitForChild("Thud")
local whooshSfx = SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI"):WaitForChild("Whoosh")

-->
local CurtainTransition = {
	ui = nil,
	tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out, 0, false, 0),
	holdDuration = 0.7,
}

function CurtainTransition:destroy()
	if not self.ui then
		return
	end
	self.ui:Destroy()
	self.ui = nil
end

function CurtainTransition:createUi()
	self:destroy()
	self.ui = InstanceCreator("ScreenGui", "CurtainTransition", playerGui, {
		-- ClipToDeviceArea = false,
		--SafeAreaCompatiblity = Enum.SafeAreaCompatibility.None,
		ScreenInsets = Enum.ScreenInsets.None,
		ResetOnSpawn = false,
		DisplayOrder = 200,
	})

	return {
		{
			Frame = InstanceCreator("Frame", "Left", self.ui, {
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0, 0.5),
				Size = UDim2.fromScale(0, 1),
				Position = UDim2.fromScale(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Attributes = {
					ClosedSize = UDim2.fromScale(0.5, 1),
				},
			}),
			Completed = false,
		},

		{
			Frame = InstanceCreator("Frame", "Right", self.ui, {
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(1, 0.5),
				Size = UDim2.fromScale(0, 1),
				Position = UDim2.fromScale(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Attributes = {
					ClosedSize = UDim2.fromScale(0.5, 1),
				},
			}),
			Completed = false,
		},
	}
end

function CurtainTransition:Play(createTween, props: { [string]: any })
	soundHandler:play(thudSfx, {
		PlayOver = true,
		Parent = SoundService,
	})

	self.Frames = self:createUi() :: {
		[number]: {
			Frame: Frame,
			Completed: boolean,
		},
	}

	local tweenInfo: TweenInfo = props["TweenInfo"] or self.tweenInfo

	self.Locked = true
	task.delay(self.holdDuration + tweenInfo.Time, function()
		self.Locked = false
	end)

	for _, data: { Frame: Frame, Completed: boolean } in pairs(self.Frames) do
		task.spawn(function()
			createTween(data.Frame, props["TweenInfo"] or self.tweenInfo, {
					Size = UDim2.fromScale(0.5, 1),
				})
				.Play()
				.Completed(function() end, {})
				.Destroy()
		end)
	end
end

function CurtainTransition:End(createTween, props)
	task.spawn(function()
		if self.Locked then
			repeat
				task.wait()
			until self.Locked == false
		end

		local function isCompleted()
			for _, data: { Completed: boolean } in pairs(self.Frames) do
				if not data.Completed then
					return false
				end
			end

			self:destroy()
			return true
		end

		soundHandler:play(whooshSfx, {
			PlayOver = true,
			Parent = SoundService,
		})

		for _, data: { Frame: Frame, Completed: boolean } in pairs(self.Frames or {}) do
			task.spawn(function()
				createTween(data.Frame, props["TweenInfo"] or self.tweenInfo, {
						Size = UDim2.fromScale(0, 1),
					})
					.Play()
					.Completed(function()
						data.Completed = true
						isCompleted()
					end, {})
					.Destroy()
			end)
		end
	end)
end

function CurtainTransition:Stop() end

return CurtainTransition
