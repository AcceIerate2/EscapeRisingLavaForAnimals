-- Helpers
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

local function gradient(...: Color3): ColorSequence
	local colors = { ... }
	if #colors == 1 then
		return ColorSequence.new(colors[1])
	end

	local keypoints = {}
	for index, color in colors do
		table.insert(keypoints, ColorSequenceKeypoint.new((index - 1) / (#colors - 1), color))
	end
	return ColorSequence.new(keypoints)
end

-->
local TrailsConfig = {}

-- Applied to every trail unless the trail overrides it.
TrailsConfig.Settings = {
	BaseWalkSpeed = 16, -- WalkSpeed is BaseWalkSpeed * the equipped trail's SpeedMultiplier.
	AttachmentHeight = 1, -- Studs above/below the HumanoidRootPart; sets the trail's width.
	AttachmentBackOffset = 0.3, -- Studs behind the HumanoidRootPart.

	Lifetime = 0.6,
	LightEmission = 0.25,
	Transparency = NumberSequence.new(0.1, 1), -- Fades out toward the end.
	WidthScale = NumberSequence.new(1, 0), -- Shrinks toward the end.
}

--[[
	Trails show in the shop in this order.
	Id: saved to player data, never change it after release.
	ProductId: Developer Product for the Robux button, 0 hides the button.
	Art / CardColor: shop card image and background gradient.
	Color: the trail itself, optional Lifetime / LightEmission / Transparency / WidthScale override Settings.
]]
TrailsConfig.Trails = {
	{
		Id = "Green",
		Name = "Green Trail",
		Rarity = "Common",
		Price = 1_000,
		ProductId = 0,
		SpeedMultiplier = 1.5,

		Art = "rbxassetid://119977823155885",
		CardColor = gradient(rgb(144, 253, 51), rgb(77, 194, 21)),
		Color = gradient(rgb(105, 255, 38)),
	},
	{
		Id = "Blue",
		Name = "Blue Trail",
		Rarity = "Rare",
		Price = 5_000,
		ProductId = 0,
		SpeedMultiplier = 2,

		Art = "rbxassetid://121495706747299",
		CardColor = gradient(rgb(30, 165, 255), rgb(14, 95, 222)),
		Color = gradient(rgb(30, 165, 255)),
	},
	{
		Id = "Purple",
		Name = "Purple Trail",
		Rarity = "Epic",
		Price = 10_000,
		ProductId = 0,
		SpeedMultiplier = 2.5,

		Art = "rbxassetid://131639556676430",
		CardColor = gradient(rgb(220, 78, 255), rgb(145, 30, 217)),
		Color = gradient(rgb(190, 60, 255)),
	},
	{
		Id = "Orange",
		Name = "Orange Trail",
		Rarity = "Legendary",
		Price = 25_000,
		ProductId = 0,
		SpeedMultiplier = 3,

		Art = "rbxassetid://104181673048071",
		CardColor = gradient(rgb(255, 204, 70), rgb(237, 135, 25)),
		Color = gradient(rgb(255, 150, 30)),
	},
	{
		Id = "Lava",
		Name = "Lava Trail",
		Rarity = "Mythic",
		Price = 100_000,
		ProductId = 0,
		SpeedMultiplier = 4,

		Art = "rbxassetid://139926828875591",
		CardColor = gradient(rgb(255, 90, 40), rgb(170, 20, 20)),
		Color = gradient(rgb(255, 240, 120), rgb(255, 120, 20), rgb(200, 20, 10)),
		Lifetime = 0.8,
		LightEmission = 0.8,
	},
	{
		Id = "Rainbow",
		Name = "Rainbow Trail",
		Rarity = "Mythic",
		Price = 500_000,
		ProductId = 0,
		SpeedMultiplier = 5,

		Art = "rbxassetid://128294965549842",
		CardColor = gradient(rgb(255, 80, 80), rgb(255, 210, 60), rgb(80, 220, 90), rgb(60, 160, 255), rgb(190, 80, 255)),
		Color = gradient(
			rgb(255, 60, 60),
			rgb(255, 160, 40),
			rgb(255, 235, 60),
			rgb(70, 230, 90),
			rgb(50, 160, 255),
			rgb(180, 70, 255)
		),
		Lifetime = 1,
		LightEmission = 0.5,
	},
}

-- Public Methods
function TrailsConfig.GetTrail(trailId: string)
	for _, trail in TrailsConfig.Trails do
		if trail.Id == trailId then
			return trail
		end
	end
	return nil
end

return TrailsConfig
