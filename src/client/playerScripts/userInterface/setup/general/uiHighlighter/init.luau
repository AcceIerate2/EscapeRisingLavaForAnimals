-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-->
local UIHighlighter = {
	UI = require(script.highlighterUI),
	CurrentUI = nil,
	Tweens = {},
}

function UIHighlighter:calculateProportions(
	ui: ScreenGui,
	config: {
		AbsoluteSize: Vector2,
		AbsolutePosition: Vector2?,
		Padding: number?,
	}
)
	local placeholder = ui:FindFirstChild("Placeholder")
	local left = ui:FindFirstChild("Left")
	local right = ui:FindFirstChild("Right")
	local top = ui:FindFirstChild("Top")
	local bottom = ui:FindFirstChild("Bottom")

	if not (placeholder and left and right and top and bottom) then
		return
	end

	local absoluteSize = config.AbsoluteSize
	local absolutePosition = config.AbsolutePosition
	local padding = config.Padding or 0

	if not absoluteSize or not absolutePosition then
		return
	end

	local screenSize = ui.AbsoluteSize

	local x = absolutePosition.X - padding
	local y = absolutePosition.Y + 56 - padding
	local width = absoluteSize.X + (padding * 2)
	local height = absoluteSize.Y + (padding * 2)

	-- clamp raw rect first
	x = math.max(0, x)
	y = math.max(0, y)
	width = math.max(0, math.min(width, screenSize.X - x))
	height = math.max(0, math.min(height, screenSize.Y - y))

	-- convert to clean pixel edges
	local leftEdge = math.floor(x)
	local topEdge = math.floor(y)
	local rightEdge = math.ceil(x + width)
	local bottomEdge = math.ceil(y + height)

	-- clamp edges
	leftEdge = math.clamp(leftEdge, 0, screenSize.X)
	topEdge = math.clamp(topEdge, 0, screenSize.Y)
	rightEdge = math.clamp(rightEdge, 0, screenSize.X)
	bottomEdge = math.clamp(bottomEdge, 0, screenSize.Y)

	local holeWidth = math.max(0, rightEdge - leftEdge)
	local holeHeight = math.max(0, bottomEdge - topEdge)

	local function setRect(obj, rx, ry, rw, rh)
		obj.AnchorPoint = Vector2.zero
		obj.BorderSizePixel = 0
		obj.Position = UDim2.fromOffset(rx, ry)
		obj.Size = UDim2.fromOffset(rw, rh)
	end

	setRect(placeholder, leftEdge, topEdge, holeWidth, holeHeight)

	setRect(left, 0, 0, leftEdge, screenSize.Y)
	setRect(right, rightEdge, 0, math.max(0, screenSize.X - rightEdge), screenSize.Y)
	setRect(top, leftEdge, 0, holeWidth, topEdge)
	setRect(bottom, leftEdge, bottomEdge, holeWidth, math.max(0, screenSize.Y - bottomEdge))
end

function UIHighlighter:Init(player: Player)
	self.Controller = knit.GetController("UIHighlighterController")
	self.Controller.DrawSignal:Connect(function(config: {
		AbsoluteSize: Vector2,
		AbsolutePosition: Vector2,
		Padding: number?,
	})
		local ui = self.CurrentUI or self.UI(player)
		self.CurrentUI = ui
		self:calculateProportions(ui, config)
	end)

	self.Controller.DestroySignal:Connect(function()
		if TypeCheck.Instance(self.CurrentUI) then
			self.CurrentUI:Destroy()
		end
		self.CurrentUI = nil
	end)
end

return UIHighlighter
