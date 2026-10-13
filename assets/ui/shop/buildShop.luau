-- One-time Studio asset builder; purchase IDs are configured separately.
-- Roblox Services
local sg = game:GetService("StarterGui")
local panels = sg.Panels
assert(not panels:FindFirstChild("Shop"), "Shop already exists")
local sell = panels.Sell.Pets
local font = sell.Header.Title.FontFace
local buttonTemplate = sell.Footer.Sell
local petTemplates = panels.Index.Collection.Forest.Pets
-- Config
local I = {
	Basket = sg.Hud.LeftMenu.Shop.Icon.Image,
	Egg = sg.Hud.RightMenu.Eggs.Icon.Image,
	Cash = sg.Hud.Counters.Cash.Icon.Image,
	Gift = panels.Rebirth.Content.Actions.Gift.Icon.Image,
	Crown = "rbxassetid://129287930864666",
	Luck = "rbxassetid://102022802356366",
	Chest = "rbxassetid://114504500127646",
	Studs = "rbxassetid://87057041051629",
	Burst = "rbxassetid://81286263439668",
}
local history = game:GetService("ChangeHistoryService")
local recording = history:TryBeginRecording("CreateShopPanel", "Create matching Shop panel")

-- Helper Functions
local function create(class, name, parent, props)
	local o = Instance.new(class)
	o.Name = name
	for k, v in props or {} do
		o[k] = v
	end
	o.Parent = parent
	return o
end
local function frame(name, parent, pos, size, color)
	return create("Frame", name, parent, {
		Position = pos,
		Size = size,
		BackgroundColor3 = color or Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 4,
	})
end
local function stroke(o, thickness, color)
	return create("UIStroke", "Outline", o, {
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		Thickness = thickness,
		Color = color or Color3.fromRGB(17, 19, 25),
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end
local function image(name, parent, id, pos, size, z)
	return create("ImageLabel", name, parent, {
		Image = id,
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = z or 7,
	})
end
local function label(name, parent, text, pos, size, color, z)
	local t = create("TextLabel", name, parent, {
		Text = text,
		FontFace = font,
		TextScaled = true,
		TextWrapped = true,
		TextColor3 = color or Color3.new(1, 1, 1),
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		ZIndex = z or 10,
	})
	create(
		"UIStroke",
		"TextOutline",
		t,
		{ StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize, Thickness = 0.06, Color = Color3.fromRGB(8, 10, 14) }
	)
	return t
end
local function gradient(o, top, bottom, rotation)
	return create("UIGradient", "Gradient", o, { Color = ColorSequence.new(top, bottom), Rotation = rotation or 90 })
end
local function studs(o, transparency)
	return create("ImageLabel", "Studs", o, {
		Image = I.Studs,
		ImageTransparency = transparency or 0.82,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(128, 128),
		ZIndex = 5,
	})
end
local function card(name, parent, pos, size, top, bottom)
	local o = frame(name, parent, pos, size)
	o.ClipsDescendants = true
	create("UICorner", "Corner", o, { CornerRadius = UDim.new(0.035, 0) })
	stroke(o, 0.008, Color3.fromRGB(10, 14, 20))
	gradient(o, top, bottom)
	studs(o, 0.82)
	return o
end
local function shiftZ(o, delta)
	if o:IsA("GuiObject") then
		o.ZIndex += delta
	end
	for _, v in o:GetDescendants() do
		if v:IsA("GuiObject") then
			v.ZIndex += delta
		end
	end
end
local function button(name, parent, text, pos, size, price, offer)
	local b = buttonTemplate:Clone()
	b.Name = name
	b.Position = pos
	b.Size = size
	b.AnchorPoint = Vector2.zero
	b.Visible = true
	b.Text = ""
	for _, tag in b:GetTags() do
		b:RemoveTag(tag)
	end
	for key in b:GetAttributes() do
		b:SetAttribute(key, nil)
	end
	b:SetAttribute("Type", "Action")
	b:AddTag("GuiButton")
	b:SetAttribute("OfferKey", offer or name)
	if price then
		b:SetAttribute("DisplayPrice", price)
	end
	b.Label.Text = text
	b.Label.TextOutline.Thickness = 0.055
	b.Outline.Thickness = 0.035
	local limit = b.Label:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MaxTextSize = 100
		limit.MinTextSize = 1
	end
	b.Parent = parent
	if price then
		b.Label.Text = utf8.char(0xE002) .. " " .. tostring(price)
		b.Label.Position = UDim2.fromScale(0.06, 0.08)
		b.Label.Size = UDim2.fromScale(0.88, 0.84)
	end
	return b
end
local function gift(parent, pos, size, key)
	local b = button("Gift", parent, "", pos, size, nil, key .. "_Gift")
	b.Gradient.Color = ColorSequence.new(Color3.fromRGB(220, 121, 255), Color3.fromRGB(149, 37, 234))
	image("GiftIcon", b, I.Gift, UDim2.fromScale(0.14, 0.1), UDim2.fromScale(0.72, 0.8), 11)
	return b
end
local function pet(parent, index, pos, size, silhouette)
	local source = petTemplates["Pet" .. index].PetPreview
	local viewport = create("ViewportFrame", "PetPreview", parent, {
		Position = pos,
		Size = size,
		BackgroundTransparency = 1,
		ZIndex = 8,
		Ambient = Color3.fromRGB(210, 210, 225),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -1, -1),
	})
	local world = create("WorldModel", "WorldModel", viewport)
	local src = source:FindFirstChildOfClass("WorldModel")
	if src then
		for _, child in src:GetChildren() do
			if child:IsA("Model") or child:IsA("BasePart") then
				local clone = child:Clone()
				for _, v in clone:GetDescendants() do
					if v:IsA("BasePart") then
						v.Anchored = true
						if silhouette then
							v.Color = Color3.fromRGB(10, 13, 22)
							v.Material = Enum.Material.SmoothPlastic
						end
					elseif v:IsA("Script") or v:IsA("LocalScript") then
						v:Destroy()
					end
				end
				clone.Parent = world
			end
		end
	end
	local model = world:FindFirstChildOfClass("Model")
	if model then
		local cf, box = model:GetBoundingBox()
		local radius = math.max(box.X, box.Y, box.Z)
		local camera = create("Camera", "PreviewCamera", viewport, {
			FieldOfView = 34,
			CFrame = CFrame.lookAt(
				cf.Position + Vector3.new(-radius * 0.75, radius * 0.25, -radius * 1.85),
				cf.Position
			),
		})
		viewport.CurrentCamera = camera
	end
	return viewport
end

local shop = sell:Clone()
shop.Name = "Shop"
shop.AnchorPoint = Vector2.new(0.5, 0.5)
shop.Position = UDim2.fromScale(0.5, 0.5)
shop.Size = panels.Index.Size
shop.Visible = true
shop.Inventory:Destroy()
shop.Footer:Destroy()
local aspect = panels.Index:FindFirstChildOfClass("UIAspectRatioConstraint")
if aspect then
	aspect:Clone().Parent = shop
end
shop.Header.Title.Text = "Exclusive Shop"
shop.Header.Icon.Image = I.Basket
shop.Header.Close:SetAttribute("Type", "PanelToggler")
shop.Header.Close:SetAttribute("PanelName", "Shop")
shop.Header.Close:AddTag("GuiButton")
shiftZ(shop.Header, 30)

local list = create("ScrollingFrame", "Offers", shop, {
	Position = UDim2.fromScale(0.018, 0.183),
	Size = UDim2.fromScale(0.967, 0.797),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	ScrollingDirection = Enum.ScrollingDirection.Y,
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = Color3.fromRGB(127, 139, 161),
	ClipsDescendants = true,
	ZIndex = 3,
	Active = true,
})
create("UIPadding", "Padding", list, {
	PaddingTop = UDim.new(0, 4),
	PaddingBottom = UDim.new(0, 8),
	PaddingLeft = UDim.new(0, 4),
	PaddingRight = UDim.new(0, 12),
})
create("UIListLayout", "Rows", list, {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 12),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
})
local rowOrder = 0
local function row(name, ratio)
	rowOrder += 1
	local r = frame(name, list, UDim2.new(), UDim2.new(1, -8, 0, 100))
	r.BackgroundTransparency = 1
	r.LayoutOrder = rowOrder
	create("UIAspectRatioConstraint", "AspectRatio", r, {
		AspectRatio = 1 / ratio,
		DominantAxis = Enum.DominantAxis.Width,
		AspectType = Enum.AspectType.ScaleWithParentSize,
	})
	return r
end

-- Featured egg: oversized art, four possible pets, and three bundle choices.
local heroRow = row("FeaturedEgg", 0.315)
local hero = card(
	"Offer",
	heroRow,
	UDim2.new(),
	UDim2.fromScale(1, 1),
	Color3.fromRGB(234, 139, 48),
	Color3.fromRGB(124, 42, 42)
)
hero:SetAttribute("OfferKey", "ExclusiveEgg")
local burst = image("Sunburst", hero, I.Burst, UDim2.fromScale(-0.08, -0.05), UDim2.fromScale(0.42, 1.1), 6)
burst.ImageTransparency = 0.62
image("EggArt", hero, I.Egg, UDim2.fromScale(0.015, 0.18), UDim2.fromScale(0.245, 0.74), 7).ImageColor3 =
	Color3.fromRGB(255, 203, 106)
label("Title", hero, "Exclusive Egg", UDim2.fromScale(0.025, 0.025), UDim2.fromScale(0.39, 0.17), nil, 11).TextXAlignment =
	Enum.TextXAlignment.Left
label("New", hero, "NEW!", UDim2.fromScale(0.06, 0.80), UDim2.fromScale(0.15, 0.13), Color3.fromRGB(255, 107, 75), 11)
local chances = { 50, 35, 14, 1 }
local ids = { 7, 4, 5, 2 }
for i, chance in chances do
	local x = 0.285 + (i - 1) * 0.174
	local preview = card(
		"Pet" .. i,
		hero,
		UDim2.fromScale(x, 0.19),
		UDim2.fromScale(0.156, 0.45),
		Color3.fromRGB(80, 57, 55),
		Color3.fromRGB(41, 30, 36)
	)
	preview.BackgroundTransparency = 0.1
	pet(preview, ids[i], UDim2.fromScale(0.08, 0.10), UDim2.fromScale(0.84, 0.85))
	label(
		"Chance",
		preview,
		chance .. "%",
		UDim2.fromScale(0.34, 0.015),
		UDim2.fromScale(0.62, 0.22),
		Color3.fromRGB(255, 222, 70),
		10
	)
end
for i, offer in { { 880, "10 Eggs" }, { 304, "3 Eggs" }, { 120, "1 Egg" } } do
	local x = 0.285 + (i - 1) * 0.232
	button(
		"Buy" .. i,
		hero,
		tostring(offer[1]),
		UDim2.fromScale(x, 0.70),
		UDim2.fromScale(0.214, 0.20),
		offer[1],
		"ExclusiveEgg_" .. i
	)
	label("Bundle" .. i, hero, offer[2], UDim2.fromScale(x, 0.904), UDim2.fromScale(0.214, 0.075), nil, 11)
end

-- Mystery eggs.
local mysteryRow = row("MysteryEggs", 0.405)
local mysteryData = {
	{ "Secret", Color3.fromRGB(51, 197, 242), Color3.fromRGB(16, 80, 129), 149, { 72.5, 25, 2.5 } },
	{ "Exclusive", Color3.fromRGB(247, 82, 103), Color3.fromRGB(123, 30, 49), 249, { 75, 19, 6 } },
	{ "Eternal", Color3.fromRGB(255, 210, 82), Color3.fromRGB(165, 91, 20), 399, { 90, 9.5, 0.5 } },
}
for i, d in mysteryData do
	local c =
		card(d[1] .. "Egg", mysteryRow, UDim2.fromScale((i - 1) * 0.339, 0), UDim2.fromScale(0.322, 1), d[2], d[3])
	label("Tier", c, d[1]:upper(), UDim2.fromScale(0.04, 0.035), UDim2.fromScale(0.92, 0.11))
	label("Name", c, "Mystery Egg", UDim2.fromScale(0.04, 0.145), UDim2.fromScale(0.92, 0.095))
	image("Glow", c, I.Burst, UDim2.fromScale(0.02, 0.22), UDim2.fromScale(0.96, 0.46), 6).ImageTransparency = 0.72
	image("Egg", c, I.Egg, UDim2.fromScale(0.21, 0.255), UDim2.fromScale(0.58, 0.32), 7).ImageColor3 =
		d[2]:Lerp(Color3.new(1, 1, 1), 0.45)
	label("MysteryMark", c, "?", UDim2.fromScale(0.35, 0.31), UDim2.fromScale(0.30, 0.23), nil, 9)
	local petBackdrop =
		frame("PetBackdrop", c, UDim2.fromScale(0.045, 0.585), UDim2.fromScale(0.91, 0.215), Color3.new(0, 0, 0))
	petBackdrop.BackgroundTransparency = 0.5
	petBackdrop.ZIndex = 6
	create("UICorner", "Corner", petBackdrop, { CornerRadius = UDim.new(0.08, 0) })
	for n, chance in d[5] do
		pet(c, ({ 3, 2, 7 })[n], UDim2.fromScale(0.06 + (n - 1) * 0.30, 0.60), UDim2.fromScale(0.27, 0.13), true)
		label(
			"Chance" .. n,
			c,
			tostring(chance) .. "%",
			UDim2.fromScale(0.06 + (n - 1) * 0.30, 0.735),
			UDim2.fromScale(0.27, 0.055)
		)
	end
	button(
		"Buy",
		c,
		tostring(d[4]),
		UDim2.fromScale(0.075, 0.815),
		UDim2.fromScale(0.85, 0.155),
		d[4],
		d[1] .. "MysteryEgg"
	)
end

local function pass(name, title, description, icon, top, bottom, price, badge)
	local r = row(name, 0.245)
	local c = card("Offer", r, UDim2.new(), UDim2.fromScale(1, 1), top, bottom)
	local iconWell =
		frame("IconWell", c, UDim2.fromScale(0.025, 0.13), UDim2.fromScale(0.235, 0.76), Color3.fromRGB(20, 28, 24))
	iconWell.BackgroundTransparency = 0.65
	iconWell.ZIndex = 6
	create("UICorner", "Round", iconWell, { CornerRadius = UDim.new(1, 0) })
	image("Icon", iconWell, icon, UDim2.fromScale(0.11, 0.08), UDim2.fromScale(0.78, 0.84), 7)
	label("Title", c, title, UDim2.fromScale(0.28, 0.06), UDim2.fromScale(0.54, 0.20)).TextXAlignment =
		Enum.TextXAlignment.Left
	label(
		"Description",
		c,
		description,
		UDim2.fromScale(0.28, 0.34),
		UDim2.fromScale(0.40, 0.48),
		Color3.fromRGB(255, 246, 195)
	).TextXAlignment =
		Enum.TextXAlignment.Left
	label(
		"Badge",
		c,
		badge or "BOOST",
		UDim2.fromScale(0.80, 0.07),
		UDim2.fromScale(0.17, 0.16),
		Color3.fromRGB(255, 99, 101)
	)
	button("Buy", c, tostring(price), UDim2.fromScale(0.70, 0.57), UDim2.fromScale(0.195, 0.31), price, name)
	gift(c, UDim2.fromScale(0.91, 0.57), UDim2.fromScale(0.072, 0.31), name)
	return c
end
pass(
	"VIP",
	"V.I.P.",
	"+25% Money\nand a VIP chat tag!",
	I.Crown,
	Color3.fromRGB(252, 219, 107),
	Color3.fromRGB(198, 135, 35),
	120,
	"VIP"
)
local luck = pass(
	"ServerLuck",
	"Server Luck",
	"",
	I.Luck,
	Color3.fromRGB(124, 239, 71),
	Color3.fromRGB(36, 147, 35),
	160,
	"NEW!"
)
label("CurrentMultiplier", luck, "x1", UDim2.fromScale(0.31, 0.37), UDim2.fromScale(0.13, 0.38))
image(
	"UpgradeArrow",
	luck,
	panels.Rebirth.Content.UpgradeArrow.Image,
	UDim2.fromScale(0.445, 0.40),
	UDim2.fromScale(0.11, 0.28),
	8
)
label(
	"NextMultiplier",
	luck,
	"x2",
	UDim2.fromScale(0.57, 0.37),
	UDim2.fromScale(0.13, 0.38),
	Color3.fromRGB(255, 205, 63)
)
luck.Gift:Destroy()
luck.Buy.Position = UDim2.fromScale(0.76, 0.56)
luck.Buy.Size = UDim2.fromScale(0.21, 0.31)
pass(
	"DoubleMoney",
	"x2 Money Boost",
	"Earn double the cash\nfrom your animals!",
	I.Cash,
	Color3.fromRGB(144, 242, 125),
	Color3.fromRGB(47, 148, 63),
	160,
	"NEW!"
)
local growth = pass(
	"DoubleEggGrowth",
	"x2 Egg Growth",
	"Your eggs hatch\nin half the time!",
	I.Egg,
	Color3.fromRGB(248, 215, 89),
	Color3.fromRGB(192, 122, 32),
	280,
	"NEW!"
)
label("Multiplier", growth.IconWell, "x2", UDim2.fromScale(0.20, 0.67), UDim2.fromScale(0.60, 0.25), nil, 11)

local starterRow = row("StarterPack", 0.215)
local starter = card(
	"Offer",
	starterRow,
	UDim2.new(),
	UDim2.fromScale(1, 1),
	Color3.fromRGB(88, 213, 242),
	Color3.fromRGB(156, 74, 213)
)
starter.Gradient.Rotation = 0
local petTile = card(
	"PetReward",
	starter,
	UDim2.fromScale(0.02, 0.08),
	UDim2.fromScale(0.19, 0.84),
	Color3.fromRGB(52, 182, 246),
	Color3.fromRGB(12, 95, 157)
)
pet(petTile, 2, UDim2.fromScale(0.02, 0.02), UDim2.fromScale(0.96, 0.76))
label("Name", petTile, "Dog", UDim2.fromScale(0.04, 0.79), UDim2.fromScale(0.92, 0.14))
local cashTile = card(
	"CashReward",
	starter,
	UDim2.fromScale(0.23, 0.08),
	UDim2.fromScale(0.19, 0.84),
	Color3.fromRGB(52, 182, 246),
	Color3.fromRGB(12, 95, 157)
)
image("Icon", cashTile, I.Cash, UDim2.fromScale(0.10, 0.10), UDim2.fromScale(0.8, 0.64))
label("Amount", cashTile, "+$5K", UDim2.fromScale(0.04, 0.78), UDim2.fromScale(0.92, 0.16))
label("Title", starter, "Starter Pack", UDim2.fromScale(0.49, 0.06), UDim2.fromScale(0.48, 0.28))
label(
	"Subtitle",
	starter,
	"LIMITED TIME",
	UDim2.fromScale(0.57, 0.38),
	UDim2.fromScale(0.35, 0.16),
	Color3.fromRGB(255, 226, 61)
)
button("Buy", starter, "9", UDim2.fromScale(0.63, 0.63), UDim2.fromScale(0.32, 0.28), 9, "StarterPack")

local megaRow = row("MegaPack", 0.225)
local mega = card(
	"Offer",
	megaRow,
	UDim2.new(),
	UDim2.fromScale(1, 1),
	Color3.fromRGB(137, 247, 77),
	Color3.fromRGB(51, 163, 48)
)
image("Chest", mega, I.Chest, UDim2.fromScale(0.02, 0.05), UDim2.fromScale(0.26, 0.90))
label("Amount", mega, "+$1,000,000", UDim2.fromScale(0.29, 0.12), UDim2.fromScale(0.51, 0.29)).TextXAlignment =
	Enum.TextXAlignment.Left
label(
	"Title",
	mega,
	"Mega Pack",
	UDim2.fromScale(0.30, 0.50),
	UDim2.fromScale(0.35, 0.24),
	Color3.fromRGB(255, 224, 70)
).TextXAlignment =
	Enum.TextXAlignment.Left
label(
	"Badge",
	mega,
	"BIG VALUE",
	UDim2.fromScale(0.75, 0.11),
	UDim2.fromScale(0.22, 0.17),
	Color3.fromRGB(255, 100, 92)
)
button("Buy", mega, "280", UDim2.fromScale(0.73, 0.60), UDim2.fromScale(0.24, 0.29), 280, "MegaPack")

local cashRow = row("CashPacks", 0.255)
for i, d in { { "+$5,000", 16 }, { "+$25,000", 40 }, { "+$100,000", 120 } } do
	local c = card(
		"CashPack" .. i,
		cashRow,
		UDim2.fromScale((i - 1) * 0.339, 0),
		UDim2.fromScale(0.322, 1),
		Color3.fromRGB(135, 235, 76),
		Color3.fromRGB(45, 146, 52)
	)
	label("Amount", c, d[1], UDim2.fromScale(0.055, 0.07), UDim2.fromScale(0.89, 0.17))
	image("Cash", c, I.Cash, UDim2.fromScale(0.15, 0.29), UDim2.fromScale(0.68, 0.40))
	button("Buy", c, tostring(d[2]), UDim2.fromScale(0.22, 0.77), UDim2.fromScale(0.56, 0.17), d[2], "CashPack" .. i)
end

-- Aspect-constrained rows need an explicit canvas to include the final row fully.
local totalRowRatio = 0
for _, item in list:GetChildren() do
	if item:IsA("Frame") then
		totalRowRatio += 1 / item.AspectRatio.AspectRatio
	end
end
local panelRatio = shop:FindFirstChildOfClass("UIAspectRatioConstraint").AspectRatio
list.AutomaticCanvasSize = Enum.AutomaticSize.None
list.CanvasSize =
	UDim2.new(0, 0, totalRowRatio * panelRatio * list.Size.X.Scale, 12 * (rowOrder - 1) + 12 - 24 * totalRowRatio)

shop:SetAttribute("PricesArePlaceholders", true)
shop.Parent = panels
sg.Hud.LeftMenu.Shop:SetAttribute("PanelName", "Shop")
for _, p in panels:GetChildren() do
	if p:IsA("GuiObject") then
		p.Visible = p == shop
	end
end
if recording then
	history:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
return { panel = shop:GetFullName(), rows = rowOrder, descendants = #shop:GetDescendants() }
