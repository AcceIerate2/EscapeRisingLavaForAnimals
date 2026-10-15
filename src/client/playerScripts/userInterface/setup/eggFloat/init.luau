-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)

-- Config
local config = {
	BobHeight = 0.05, -- fraction of the egg's height it floats up/down
	BobSpeed = 2.2, -- radians per second
	ShakeEvery = 1.5, -- seconds between shakes
	ShakeTime = 0.4,
	ShakeTilt = 9, -- degrees (images only; viewports don't render rotation)
	ShakeNudge = 0.04, -- fraction of the egg's width it jiggles sideways
}

-- Shop eggs that float: paths under Shop.Offers, "*" = every child.
local targets = {
	"FeaturedEgg/Offer/EggArt",
	"MysteryEggs/*/EggPreview",
}

-->
local EggFloat = {
	Eggs = {},
}

-- Private Methods
function EggFloat:collect(offers: Instance)
	for _, path in targets do
		local current = { offers }
		for _, segment in string.split(path, "/") do
			local nextLevel = {}
			for _, parent in current do
				for _, child in parent:GetChildren() do
					if segment == "*" or child.Name == segment then
						table.insert(nextLevel, child)
					end
				end
			end
			current = nextLevel
		end

		for index, egg in current do
			if egg:IsA("GuiObject") then
				table.insert(self.Eggs, {
					Instance = egg,
					Home = egg.Position,
					Rotation = egg.Rotation,
					Phase = (#self.Eggs + index) * 0.9, -- eggs bob out of step
					CanRotate = not egg:IsA("ViewportFrame"),
				})
			end
		end
	end
end

function EggFloat:update(clock: number)
	for _, egg in self.Eggs do
		local instance = egg.Instance
		local size = instance.AbsoluteSize
		local bob = math.sin(clock * config.BobSpeed + egg.Phase) * size.Y * config.BobHeight

		-- A quick decaying wobble once every ShakeEvery seconds (each egg offset a little).
		local shakeClock = (clock + egg.Phase * 0.2) % config.ShakeEvery
		local nudge, tilt = 0, 0
		if shakeClock < config.ShakeTime then
			local decay = 1 - shakeClock / config.ShakeTime
			local wave = math.sin(shakeClock * 45) * decay
			nudge = wave * size.X * config.ShakeNudge
			tilt = wave * config.ShakeTilt
		end

		instance.Position = egg.Home + UDim2.fromOffset(nudge, bob)
		if egg.CanRotate then
			instance.Rotation = egg.Rotation + tilt
		end
	end
end

-- LifeCycle
function EggFloat:Init(_player: Player)
	local shop = utility.getPanel("Shop")
	if not shop then
		return
	end
	self:collect(shop:WaitForChild("Offers"))

	-- Only animates while the shop is on screen.
	RunService.RenderStepped:Connect(function()
		if shop.Visible then
			self:update(os.clock())
		end
	end)
end

return EggFloat
