-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Essentials
local template = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Gui"):WaitForChild("AffordNotification")
local bobHeight = 0.35 -- studs the badge bobs up and down
local bobTime = 0.6 -- seconds per bob
local gap = 1.4 -- studs between the part's top and the badge's centre

-->
-- The "!" badge that floats over a sign while its upgrade is affordable.
local AffordBadge = {}
AffordBadge.__index = AffordBadge

function AffordBadge.new(adornee: BasePart)
	local self = setmetatable({}, AffordBadge)
	self.Gui = template:Clone()
	self.Gui.Enabled = false
	self.Gui.Adornee = adornee
	self.Gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")
	self.Size = self.Gui.Size
	self.Base = Vector3.new(0, adornee.Size.Y / 2 + gap, 0)
	self.Gui.StudsOffsetWorldSpace = self.Base
	return self
end

function AffordBadge:SetAdornee(adornee: BasePart?)
	self.Gui.Adornee = adornee
	if adornee then
		self.Base = Vector3.new(0, adornee.Size.Y / 2 + gap, 0)
	end
end

function AffordBadge:Show(visible: boolean)
	if visible == self.Gui.Enabled then
		return
	end
	self.Gui.Enabled = visible

	if self.Bob then
		self.Bob:Cancel()
		self.Bob = nil
	end
	if not visible then
		return
	end

	-- Pops in, then bobs gently.
	self.Gui.Size = UDim2.fromScale(self.Size.X.Scale * 0.3, self.Size.Y.Scale * 0.3)
	TweenService:Create(self.Gui, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Size = self.Size }):Play()
	self.Gui.StudsOffsetWorldSpace = self.Base
	self.Bob = TweenService:Create(
		self.Gui,
		TweenInfo.new(bobTime, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{ StudsOffsetWorldSpace = self.Base + Vector3.new(0, bobHeight, 0) }
	)
	self.Bob:Play()
end

function AffordBadge:Destroy()
	if self.Bob then
		self.Bob:Cancel()
	end
	self.Gui:Destroy()
end

return AffordBadge
