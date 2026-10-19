local gui = game.StarterGui.LeaderboardTemplate
local function make(class, name, parent, props)
	local item = parent:FindFirstChild(name) or Instance.new(class)
	item.Name = name
	for key, value in props do
		item[key] = value
	end
	item.Parent = parent
	return item
end
local function corner(item, radius)
	make("UICorner", "CartoonCorner", item, { CornerRadius = UDim.new(0, radius) })
end
local function stroke(item, thickness, color)
	for _, v in item:GetChildren() do
		if v:IsA("UIStroke") then
			v:Destroy()
		end
	end
	make("UIStroke", "Outline", item, {
		Color = color or Color3.fromRGB(46, 21, 9),
		Thickness = thickness,
		StrokeSizingMode = Enum.StrokeSizingMode.ScaledSize,
		ApplyStrokeMode = item:IsA("TextLabel") and Enum.ApplyStrokeMode.Contextual or Enum.ApplyStrokeMode.Border,
	})
end
local function text(item, size)
	item.FontFace = Font.new("rbxasset://fonts/families/FredokaOne.json", Enum.FontWeight.Regular)
	item.TextColor3 = Color3.new(1, 1, 1)
	item.TextScaled = true
	item.TextWrapped = false
	item.BackgroundTransparency = 1
	stroke(item, 0.055, Color3.fromRGB(35, 17, 8))
	local limit = item:FindFirstChildOfClass("UITextSizeConstraint")
	if limit then
		limit.MaxTextSize = size
		limit.MinTextSize = 10
	end
end
local function texture(item)
	make("ImageLabel", "Studs", item, {
		BackgroundTransparency = 1,
		Image = "rbxassetid://87057041051629",
		ImageTransparency = 0.86,
		Size = UDim2.fromScale(1, 1),
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(96, 96),
		ZIndex = 1,
	})
end
gui.SizingMode = Enum.SurfaceGuiSizingMode.FixedSize
gui.CanvasSize = Vector2.new(600, 960)
gui.LightInfluence = 0
gui.Enabled = false
local bg = gui.Background
bg.BackgroundColor3 = Color3.fromRGB(220, 91, 14)
bg.BackgroundTransparency = 0
bg.BorderSizePixel = 0
corner(bg, 22)
stroke(bg, 0.013)
texture(bg)
make(
	"UIGradient",
	"WarmGradient",
	bg,
	{ Color = ColorSequence.new(Color3.fromRGB(255, 166, 33), Color3.fromRGB(182, 60, 9)), Rotation = 90 }
)
local body = make("Frame", "Inset", bg, {
	Position = UDim2.fromOffset(14, 14),
	Size = UDim2.new(1, -28, 1, -28),
	BackgroundColor3 = Color3.fromRGB(255, 154, 24),
	BorderSizePixel = 0,
	ZIndex = 2,
})
corner(body, 14)
stroke(body, 0.004, Color3.fromRGB(255, 209, 93))
texture(body)
local header = gui.Header
header.BackgroundTransparency = 1
header.Position = UDim2.fromOffset(22, 12)
header.Size = UDim2.new(1, -44, 0, 150)
header.ZIndex = 3
local title = header.Title
title.Position = UDim2.fromOffset(84, 63)
title.Size = UDim2.new(1, -94, 0, 60)
title.AnchorPoint = Vector2.zero
title.TextXAlignment = Enum.TextXAlignment.Left
text(title, 50)
local icon = make("ImageLabel", "Icon", header, {
	Image = "rbxassetid://89125230077129",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(17, 58),
	Size = UDim2.fromOffset(60, 64),
	ZIndex = 3,
})
local countdown = header.Countdown
countdown.AnchorPoint = Vector2.zero
countdown.Position = UDim2.new(0.23, 0, 0, 8)
countdown.Size = UDim2.new(0.54, 0, 0, 36)
text(countdown, 25)
countdown.Text = "Updates in 2:00"
countdown.BackgroundColor3 = Color3.fromRGB(125, 47, 11)
countdown.BackgroundTransparency = 0.12
corner(countdown, 12)
header.Accent.Position = UDim2.new(0, 14, 1, -8)
header.Accent.Size = UDim2.new(1, -28, 0, 5)
corner(header.Accent, 3)
local list = gui.List
list.Position = UDim2.fromOffset(28, 176)
list.Size = UDim2.new(1, -56, 0, 626)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 5
list.ScrollBarImageColor3 = Color3.fromRGB(255, 228, 135)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.CanvasSize = UDim2.new()
list.ZIndex = 3
list.Layout.Padding = UDim.new(0, 6)
local pad = list.Padding
pad.PaddingLeft = UDim.new(0, 4)
pad.PaddingRight = UDim.new(0, 12)
pad.PaddingTop = UDim.new(0, 3)
pad.PaddingBottom = UDim.new(0, 3)
local function row(r, height)
	r.Size = UDim2.new(1, 0, 0, height)
	r.BackgroundColor3 = Color3.fromRGB(102, 38, 6)
	r.BackgroundTransparency = 0.8
	r.BorderSizePixel = 0
	corner(r, 10)
	local rank = r.Rank
	rank.AnchorPoint = Vector2.new(0, 0.5)
	rank.Position = UDim2.new(0, 7, 0.5, 0)
	rank.Size = UDim2.fromOffset(43, 43)
	text(rank, 30)
	rank.BackgroundTransparency = 0
	corner(rank, 13)
	local avatar = r.Avatar
	avatar.AnchorPoint = Vector2.new(0, 0.5)
	avatar.Position = UDim2.new(0, 60, 0.5, 0)
	avatar.Size = UDim2.fromOffset(44, 44)
	avatar.BackgroundColor3 = Color3.fromRGB(255, 225, 150)
	avatar.BackgroundTransparency = 0
	corner(avatar, 22)
	stroke(avatar, 0.04, Color3.fromRGB(83, 37, 11))
	local name = r.PlayerName
	name.AnchorPoint = Vector2.new(0, 0.5)
	name.Position = UDim2.new(0, 115, 0.5, 0)
	name.Size = UDim2.new(0.65, -115, 0, 30)
	name.TextXAlignment = Enum.TextXAlignment.Left
	text(name, 28)
	local value = r.Value
	value.AnchorPoint = Vector2.new(1, 0.5)
	value.Position = UDim2.new(1, -9, 0.5, 0)
	value.Size = UDim2.new(0.34, -6, 0, 33)
	value.TextXAlignment = Enum.TextXAlignment.Right
	text(value, 29)
end
row(list.Template, 59)
list.Template.Visible = false
text(list.Empty, 28)
list.Empty.Size = UDim2.new(1, 0, 0, 54)
list.Empty.Text = "Be the first on the board!"
local footer = gui.Footer
footer.Position = UDim2.new(0, 24, 1, -22)
footer.AnchorPoint = Vector2.new(0, 1)
footer.Size = UDim2.new(1, -48, 0, 122)
footer.BackgroundTransparency = 1
footer.ZIndex = 3
footer.Divider.Position = UDim2.fromOffset(8, 0)
footer.Divider.Size = UDim2.new(1, -16, 0, 3)
footer.Divider.BackgroundColor3 = Color3.fromRGB(255, 216, 110)
footer.Caption.Position = UDim2.fromOffset(0, 10)
footer.Caption.Size = UDim2.new(1, 0, 0, 28)
footer.Caption.Text = "YOUR SPOT"
text(footer.Caption, 26)
local mine = footer.MyStats
mine.Position = UDim2.fromOffset(4, 47)
row(mine, 66)
mine.Size = UDim2.new(1, -8, 0, 66)
mine.BackgroundTransparency = 0.32
stroke(mine, 0.018, Color3.fromRGB(255, 217, 105))
mine.Edge.Position = UDim2.fromOffset(0, 10)
mine.Edge.Size = UDim2.new(0, 4, 1, -20)
corner(mine.Edge, 2)
return "Cartoon leaderboard template styled"
