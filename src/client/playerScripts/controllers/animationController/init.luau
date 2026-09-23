-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Config
local characterAnimations = require(ReplicatedStorage.src.GameConfiguration.Gameplay.characterAnimations)

-->
local AnimationController = knit.CreateController({
	Name = "AnimationController",
	AnimationTracks = {},
	Player = Players.LocalPlayer,
	Utility = require(script.utility),
})

-- Public Methods
function AnimationController:StopAnimations(blacklist: { string })
	blacklist = blacklist or {}
	for animationName: string, animationTrack: AnimationTrack in pairs(self.AnimationTracks) do
		local shouldSkip = table.find(blacklist, animationName)
		if shouldSkip then
			continue
		end
		animationTrack:Stop()
	end
end

function AnimationController:UpdateTrackState(animationName: string, newState: string, args: { any? }): AnimationTrack?
	if not self.Utility.AnimationExists(self, animationName) then
		warn(`{animationName} animation doesn't exist - animationController:updateTrackState`)
		return
	end

	local animationTrack: AnimationTrack = self.AnimationTracks[animationName]

	local fn = animationTrack[newState]
	if typeof(fn) ~= "function" then
		warn(`Invalid AnimationTrack method: {newState}`)
		return
	end

	SafeFunctionCaller(fn, animationTrack, table.unpack(args))
	return animationTrack
end

function AnimationController:Stop(animationName: string, args: { any? }?): AnimationTrack?
	return self:updateTrackState(animationName, "Stop", args or {})
end

function AnimationController:Play(
	animationName: string,
	stopOtherAnimations: boolean?,
	args: { any? }?
): AnimationTrack?
	if stopOtherAnimations == true then
		self:stopAnimations()
	end
	return self:updateTrackState(animationName, "Play", args or {})
end

function AnimationController:unloadAnimation(animationName: string)
	if not self.Utility.AnimationExists(self, animationName) then
		return
	end

	local animationTrack: AnimationTrack = self.AnimationTracks[animationName]
	if not TypeCheck.Instance(animationTrack) or not animationTrack:IsA("AnimationTrack") then
		return
	end

	animationTrack:Stop()
	animationTrack:Destroy()

	self.AnimationTracks[animationName] = nil
end

-- Private Methods
function AnimationController:loadAnimation(animationName: string, animationData)
	if not TypeCheck.table(animationData) then
		return
	end

	local animationId: string = animationData.id
	local animationProps = animationData.props
	local methodsToCallOnLoad = animationData.methodsToCallOnLoad

	local animationInstance: Animation = InstanceCreator("Animation", animationName, script, {
		AnimationId = animationId,
	}) :: Animation

	local animationTrack: AnimationTrack = self.Animator:LoadAnimation(animationInstance)
	animationInstance:Destroy()

	-- Load custom properties
	for propName: string, propValue: any? in pairs(animationProps) do
		local ok, err = pcall(function()
			animationTrack[propName] = propValue
		end)

		if not ok then
			warn(err)
		end
	end

	-- Add to AnimationTracks
	self.AnimationTracks[animationName] = animationTrack

	task.wait()
	-- Any methods that should be called on load
	for method: string, args: { any? } in pairs(methodsToCallOnLoad) do
		if not TypeCheck.string(method) or not TypeCheck.table(args) then
			continue
		end
		self:updateTrackState(animationName, method, {})
	end
end

function AnimationController:loadAnimations()
	for animationName: string, animationData in pairs(characterAnimations) do
		self:unloadAnimation(animationName)
		self:loadAnimation(animationName, animationData)
	end
end

-- LifeCycle
function AnimationController:KnitInit()
	local function defineNewCharacter(newCharacter)
		self.Character = newCharacter
		self.Humanoid = newCharacter:WaitForChild("Humanoid", 5)
		if not self.Humanoid then
			warn('newCharacter:WaitForChild("Humanoid", 5) Timed out!')
			return
		end

		self.Animator = self.Humanoid:WaitForChild("Animator", 5)
		if not self.Animator then
			warn('self.Humanoid:WaitForChild("Animator", 5) Timed out!')
			return
		end

		self:loadAnimations()
	end

	if TypeCheck.Instance(self.Player.Character) then
		defineNewCharacter(self.Player.Character)
	end

	self.Player.CharacterAdded:Connect(defineNewCharacter)
end

return AnimationController
