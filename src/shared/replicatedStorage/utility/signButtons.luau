-- Roblox Services
local MarketplaceService = game:GetService("MarketplaceService")

-- Essentials
local robuxGlyph = utf8.char(0xE002)
local prices = {} -- [productId] = PriceInRobux, fetched once
local red = {
	Gradient = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 92, 92)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(214, 30, 40)),
	}),
	Depth = Color3.fromRGB(140, 10, 20),
}
local gap = 10 -- pixels between the price button and the Robux button
local robuxWidth = 1.4 -- the Robux button's width, in button heights (room for the icon and price)

-->
-- The buy buttons on an upgrade sign (PlotSignTemplate / TreadmillSignTemplate). Affordable: the full
-- width green price button. Not affordable: the price button turns red and shrinks to make room for
-- the purple Robux button (icon and price) next to it.
local SignButtons = {}

local layouts = setmetatable({}, { __mode = "k" }) -- [gui] = original look and "Affordable" state

local function colorButton(button: GuiButton, gradient: ColorSequence, depth: Color3)
	button.Gradient.Color = gradient
	button.Depth3D.BackgroundColor3 = depth
	button.Depth3D.SquareTop.BackgroundColor3 = depth
end

-- The hover/press animation remembers a button's size when it's linked, so re-link after resizing.
local function resize(buttonsController, button: GuiButton, size: UDim2, position: UDim2)
	buttonsController:Unlink(button)
	button:SetAttribute("DefaultSize", size)
	button.Size = size
	button.Position = position
	buttonsController:Link(button)

	-- The price text fills the space right of the button's icon (if it has one) at any width.
	local icon, label = button:FindFirstChild("Icon"), button:FindFirstChild("Label")
	if icon and label then
		local iconRight = icon.Position.X.Scale + (icon.Size.Y.Scale * size.Y.Offset) / size.X.Offset
		local start = iconRight + 0.02
		label.Position = UDim2.new(start, 0, label.Position.Y.Scale, label.Position.Y.Offset)
		label.Size = UDim2.new(0.96 - start, 0, label.Size.Y.Scale, label.Size.Y.Offset)
	end
end

function SignButtons.Set(buttonsController, gui: SurfaceGui, affordable: boolean)
	local upgrade, robux = gui.Upgrade, gui.Robux
	local layout = layouts[gui]
	if not layout then
		layout = {
			Size = upgrade:GetAttribute("DefaultSize") or upgrade.Size,
			Position = upgrade.Position,
			Gradient = upgrade.Gradient.Color,
			Depth = upgrade.Depth3D.BackgroundColor3,
		}
		layouts[gui] = layout
	end
	if layout.Affordable == affordable then
		return
	end
	layout.Affordable = affordable

	local full, position = layout.Size, layout.Position
	if affordable then
		colorButton(upgrade, layout.Gradient, layout.Depth)
		resize(buttonsController, upgrade, full, position)
		robux.Visible = false
		return
	end

	-- [ price ][gap][ R$ 400 ] across the same width the full button had.
	local height = full.Y.Offset
	local robuxW = height * robuxWidth
	local width = full.X.Offset - robuxW - gap
	local left = -full.X.Offset / 2
	colorButton(upgrade, red.Gradient, red.Depth)
	resize(
		buttonsController,
		upgrade,
		UDim2.new(full.X.Scale, width, full.Y.Scale, full.Y.Offset),
		position + UDim2.fromOffset(left + width / 2, 0)
	)
	resize(
		buttonsController,
		robux,
		UDim2.fromOffset(robuxW, height),
		position + UDim2.fromOffset(left + width + gap + robuxW / 2, 0)
	)
	robux.Visible = true
end

-- Shows the product's Robux price on the Robux button (just the Robux icon if it isn't set up yet).
function SignButtons.SetPrice(gui: SurfaceGui, productId: number?)
	local label = gui.Robux.Label
	label.Text = robuxGlyph
	gui:SetAttribute("RobuxProductId", productId)
	if not productId or productId == 0 then
		return
	end
	if prices[productId] then
		label.Text = `{robuxGlyph} {prices[productId]}`
		return
	end
	task.spawn(function()
		local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, productId, Enum.InfoType.Product)
		if ok and info and info.PriceInRobux then
			prices[productId] = info.PriceInRobux
			if gui:GetAttribute("RobuxProductId") == productId then
				label.Text = `{robuxGlyph} {info.PriceInRobux}`
			end
		end
	end)
end

return SignButtons
