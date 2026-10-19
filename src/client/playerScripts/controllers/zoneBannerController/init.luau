-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local holdTime = 1.25 -- seconds the banner stays up
local popTweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local fadeTweenInfo = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

-->
-- Shows "<Zone> Zone" at the top of the screen whenever the player reaches a new zone in the pit.
local ZoneBannerController = knit.CreateController({
	Name = "ZoneBannerController",
	ShowCount = 0,
})

-- Public Methods
function ZoneBannerController:Show(zone)
	local banner = self.Banner
	if not banner or not zone then
		return
	end

	self.ShowCount += 1
	local showId = self.ShowCount
	local zoneName = zone.Id or zone.Name

	banner.Text = `<font color="#{zone.Color:ToHex()}">{zoneName}</font> Zone`
	banner.TextTransparency = 0
	banner.TextOutline.Transparency = 0
	banner.Pop.Scale = 0.4
	banner.Visible = true
	TweenService:Create(banner.Pop, popTweenInfo, { Scale = 1 }):Play()

	task.delay(holdTime, function()
		if self.ShowCount ~= showId then
			return -- a newer zone took over the banner
		end

		TweenService:Create(banner, fadeTweenInfo, { TextTransparency = 1 }):Play()
		local fade = TweenService:Create(banner.TextOutline, fadeTweenInfo, { Transparency = 1 })
		fade.Completed:Connect(function()
			if self.ShowCount == showId then
				banner.Visible = false
			end
		end)
		fade:Play()
	end)
end

-- LifeCycle
function ZoneBannerController:KnitStart()
	task.spawn(function()
		self.Banner = Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Hud"):WaitForChild("ZoneBanner")
		self.Banner.Visible = false

		knit.GetController("LavaHudController").ZoneChanged:Connect(function(zone)
			self:Show(zone)
		end)
	end)
end

return ZoneBannerController
