-- Roblox Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local lavaConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.lavaConfig)

-->
-- Draws every rising wave locally from ReplicatedStorage.LavaState (published by LavaService). Each
-- wave is a copy of its mutation's part, sized to the shaft once and then only moved up, so it rises
-- smoothly and matches the height the server damages players at.
local LavaController = knit.CreateController({
	Name = "LavaController",
	WaveAdded = Signal.new(), -- (wave: Folder)
	WaveRemoved = Signal.new(), -- (wave: Folder)
	Slabs = {}, -- [wave] = BasePart
})

-- Public Methods
function LavaController:GetWaves(): { Folder }
	return if self.State then self.State:GetChildren() else {}
end

-- Surface height of a wave above the pit floor.
function LavaController:GetElevation(wave: Folder): number
	return lavaConfig.HeightAt(wave:GetAttributes(), workspace:GetServerTimeNow())
end

function LavaController:GetType(wave: Folder)
	return lavaConfig.GetType(wave:GetAttribute("Type") or "")
end

-- Private Methods
-- Fades a finished wave's slab, its sign and its sound out, then destroys it.
local function fadeOut(slab: BasePart)
	local info = TweenInfo.new(lavaConfig.FadeTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local function fade(instance: Instance, goal)
		TweenService:Create(instance, info, goal):Play()
	end

	fade(slab, { Transparency = 1 })
	for _, child in slab:GetDescendants() do
		if child:IsA("Decal") or child:IsA("Texture") or child:IsA("UIStroke") then
			fade(child, { Transparency = 1 })
		elseif child:IsA("ImageLabel") or child:IsA("ImageButton") then
			fade(child, { ImageTransparency = 1, BackgroundTransparency = 1 })
		elseif child:IsA("TextLabel") or child:IsA("TextButton") then
			fade(child, { TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1 })
		elseif child:IsA("Frame") then
			fade(child, { BackgroundTransparency = 1 })
		elseif child:IsA("Light") then
			fade(child, { Brightness = 0 })
		elseif child:IsA("Sound") then
			fade(child, { Volume = 0 })
		elseif child:IsA("ParticleEmitter") or child:IsA("Beam") or child:IsA("Trail") then
			child.Enabled = false
		end
	end
	Debris:AddItem(slab, lavaConfig.FadeTime)
end

function LavaController:getOrigin(): CFrame?
	local map = workspace:FindFirstChild("GeneratedMap")
	local cframe = map and map:GetAttribute("ReferenceCFrame")
	local size = map and map:GetAttribute("ReferenceSize")
	local depth = map and map:GetAttribute("Depth")
	if not (cframe and size and depth) then
		return nil
	end
	return cframe * CFrame.new(0, size.Y / 2 - depth, 0)
end

function LavaController:addWave(wave: Folder)
	local mutation = lavaConfig.GetMutation(wave:GetAttribute("Mutation"))
	local lavaType = self:GetType(wave)
	local template = mutation and self.Templates:FindFirstChild(mutation.Template)
	if not template or not lavaType then
		return
	end

	-- Sized to the shaft once; Half covers half of it across Z.
	local width = wave:GetAttribute("HalfExtent") * 2
	local slab = template:Clone()
	slab.Name = wave.Name
	slab.Anchored = true
	slab.CanCollide = false
	slab.CanTouch = false
	slab.CanQuery = false
	slab.Size = Vector3.new(width, template.Size.Y, if mutation.Id == "Half" then width / 2 else width)
	slab.Color = lavaType.Color

	-- The Full part's sign shows the type.
	local sign = slab:FindFirstChildOfClass("SurfaceGui")
	if sign then
		local emoji = sign:FindFirstChildWhichIsA("ImageLabel", true)
		local label = sign:FindFirstChildWhichIsA("TextLabel", true)
		if emoji then
			emoji.Image = lavaType.Emoji
		end
		if label then
			label.Text = string.upper(lavaType.Id)
		end
	end

	local sound = Instance.new("Sound")
	sound.Name = "Bubbling"
	sound.SoundId = lavaConfig.SoundId
	sound.Looped = true
	sound.Volume = lavaConfig.SoundVolume
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = lavaConfig.SoundRollOffMin
	sound.RollOffMaxDistance = lavaConfig.SoundRollOffMax
	sound.Parent = slab

	slab.Parent = self.Folder
	sound:Play()
	self.Slabs[wave] = slab
	self:place(wave, slab)
	self.WaveAdded:Fire(wave)
end

function LavaController:removeWave(wave: Folder)
	local slab = self.Slabs[wave]
	if slab then
		self.Slabs[wave] = nil
		fadeOut(slab)
	end
	self.WaveRemoved:Fire(wave)
end

-- Moves a wave's slab so its top sits at the wave's height.
function LavaController:place(wave: Folder, slab: BasePart)
	local origin = self:getOrigin()
	if not origin or not wave:GetAttribute("StartTime") then
		return
	end

	local height = self:GetElevation(wave)
	local offsetZ = if wave:GetAttribute("Mutation") == "Half"
		then lavaConfig.HalfOffset(wave:GetAttribute("HalfExtent"), height)
		else 0
	slab.CFrame = origin * CFrame.new(0, height - slab.Size.Y / 2, offsetZ)
end

-- LifeCycle
function LavaController:KnitStart()
	task.spawn(function()
		self.State = ReplicatedStorage:WaitForChild("LavaState")
		self.Templates = ReplicatedStorage:WaitForChild(lavaConfig.TemplateFolder)

		local folder = Instance.new("Folder")
		folder.Name = "Lava"
		folder.Parent = workspace
		self.Folder = folder

		self.State.ChildAdded:Connect(function(wave)
			-- Attributes arrive with the instance; wait a frame in case they trail.
			task.defer(self.addWave, self, wave)
		end)
		self.State.ChildRemoved:Connect(function(wave)
			self:removeWave(wave)
		end)
		for _, wave in self.State:GetChildren() do
			self:addWave(wave)
		end

		RunService.RenderStepped:Connect(function()
			for wave, slab in self.Slabs do
				self:place(wave, slab)
			end
		end)
	end)
end

return LavaController
