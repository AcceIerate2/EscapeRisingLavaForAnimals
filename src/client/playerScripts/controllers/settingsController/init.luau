-- Roblox Services
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)
local topbarplus = require(ReplicatedStorage.src.Packages.topbarplus)

-- Utility
local Spring = require(ReplicatedStorage.src.utility.Spring)

-- Config
local settingsConfig = require(ReplicatedStorage.src.GameConfiguration.General.settingsConfig)
local colorTweenInfo = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local switchStyles = { -- same look as the Slow Mode switch
	[true] = { KnobX = 0.58, Knob = Color3.fromRGB(113, 247, 30), Track = Color3.fromRGB(31, 55, 30) },
	[false] = { KnobX = 0.06, Knob = Color3.fromRGB(255, 63, 69), Track = Color3.fromRGB(60, 22, 26) },
}
local effectClasses = { "ParticleEmitter", "Trail", "Beam", "Smoke", "Fire", "Sparkles" }

-- Essentials
local player = Players.LocalPlayer

-->
local SettingsController = knit.CreateController({
	Name = "SettingsController",
	Config = settingsConfig,
	Values = {},
	SoundGroups = {},
	Disabled = setmetatable({}, { __mode = "k" }), -- effects turned off by Low Graphics
})

-- Public Methods
function SettingsController:Get(key: string): any
	return self.Values[key]
end

-- Applies immediately; `save` sends it to the server (sliders only save when released).
function SettingsController:Set(key: string, value: any, save: boolean?)
	self.Values[key] = value
	self:apply(key)
	self:render(key)
	if save then
		self.SettingsService:SetSetting(key, value):catch(warn)
	end
end

function SettingsController:ResetToDefaults()
	for key, value in self.Config.GetDefaults() do
		self:Set(key, value, false)
	end
	self.SettingsService:ResetSettings():catch(warn)
end

-- Private Methods
-- Every sound under SoundService.src.<folder> plays through a SoundGroup, so one volume controls them all
-- (clones made by soundHandler keep their group).
function SettingsController:setupSoundGroups()
	local src = SoundService:WaitForChild("src")
	for key, folderName in self.Config.SoundGroups do
		local group = Instance.new("SoundGroup")
		group.Name = `{key}Volume`
		group.Parent = SoundService
		self.SoundGroups[key] = group

		local folder = src:WaitForChild(folderName)
		local function assign(sound: Instance)
			if sound:IsA("Sound") then
				sound.SoundGroup = group
			end
		end
		for _, sound in folder:GetDescendants() do
			assign(sound)
		end
		folder.DescendantAdded:Connect(assign)
	end
end

function SettingsController:isEffect(instance: Instance): boolean
	for _, className in effectClasses do
		if instance:IsA(className) then
			return true
		end
	end
	return false
end

function SettingsController:setLowGraphics(enabled: boolean)
	if self.LowGraphicsConnection then
		self.LowGraphicsConnection:Disconnect()
		self.LowGraphicsConnection = nil
	end

	if enabled then
		self.Shadows = if self.Shadows == nil then Lighting.GlobalShadows else self.Shadows
		Lighting.GlobalShadows = false

		local function disable(instance: Instance)
			if (self:isEffect(instance) or instance:IsA("PostEffect")) and instance.Enabled then
				self.Disabled[instance] = true
				instance.Enabled = false
			end
		end
		for _, instance in workspace:GetDescendants() do
			disable(instance)
		end
		for _, instance in Lighting:GetChildren() do
			disable(instance)
		end
		self.LowGraphicsConnection = workspace.DescendantAdded:Connect(disable)
	else
		if self.Shadows ~= nil then
			Lighting.GlobalShadows = self.Shadows
		end
		for instance in self.Disabled do
			if instance.Parent then
				instance.Enabled = true
			end
		end
		table.clear(self.Disabled)
	end
end

function SettingsController:apply(key: string)
	local value = self.Values[key]
	if self.SoundGroups[key] then
		self.SoundGroups[key].Volume = value
	elseif key == "LowGraphics" then
		self:setLowGraphics(value)
	end
end

function SettingsController:render(key: string)
	local setting = self.Config.Settings[key]
	local row = self.Panel and self.Panel:FindFirstChild(setting.Row)
	if not row then
		return
	end

	local value = self.Values[key]
	if setting.Type == "Volume" then
		row.Slider.Fill.Size = UDim2.fromScale(value, 1)
		row.Slider.Knob.Position = UDim2.fromScale(value, 0.5)
		row.Value.Text = `{math.round(value * 100)}%`
	elseif setting.Type == "Toggle" then
		local track = row.Switch.Track
		local style = switchStyles[value == true]
		Spring.target(track.Knob, 0.55, 6, {
			Position = UDim2.new(style.KnobX, 0, track.Knob.Position.Y.Scale, track.Knob.Position.Y.Offset),
		})
		TweenService:Create(track.Knob, colorTweenInfo, { BackgroundColor3 = style.Knob }):Play()
		TweenService:Create(track, colorTweenInfo, { BackgroundColor3 = style.Track }):Play()
	end
end

function SettingsController:bindSlider(key: string, slider: GuiButton)
	local dragging = false

	local function update(x: number)
		local alpha = math.clamp((x - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
		self:Set(key, math.round(alpha * 100) / 100, false)
	end

	slider.InputBegan:Connect(function(input: InputObject)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(input.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			update(input.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
			dragging = false
			self:Set(key, self.Values[key], true)
		end
	end)
end

function SettingsController:bindPanel()
	self.Panel = player:WaitForChild("PlayerGui"):WaitForChild("Panels"):WaitForChild("Settings")

	for key, setting in self.Config.Settings do
		local row = self.Panel:WaitForChild(setting.Row)
		if setting.Type == "Volume" then
			self:bindSlider(key, row:WaitForChild("Slider"))
		elseif setting.Type == "Toggle" then
			row:WaitForChild("Switch").Activated:Connect(function()
				self:Set(key, not self.Values[key], true)
			end)
		end
		self:render(key)
	end
end

function SettingsController:createTopbarButton()
	local panelController = knit.GetController("PanelController")
	self.TopbarIcon = topbarplus
		.new()
		:setName("Settings")
		:setImage("rbxasset://textures/ui/Settings/MenuBarIcons/GameSettingsTab.png")
		:setImageScale(0.55)
		:setCaption("Settings")
		:setOrder(1)
		:oneClick()

	self.TopbarIcon.selected:Connect(function()
		panelController:TogglePanel("Settings")
	end)
end

-- LifeCycle
function SettingsController:KnitInit()
	self.SettingsService = knit.GetService("SettingsService")
	self.DataController = knit.GetController("DataController")
end

function SettingsController:KnitStart()
	self:setupSoundGroups()

	local saved = self.DataController:GetValue("Settings")
	for key in self.Config.Settings do
		self.Values[key] = saved[key]
		self:apply(key)
	end

	self:createTopbarButton()
	task.spawn(function()
		self:bindPanel()
	end)
end

return SettingsController
