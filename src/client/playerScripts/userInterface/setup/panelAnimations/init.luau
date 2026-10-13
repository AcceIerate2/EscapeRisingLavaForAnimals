-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)
local soundHandler = require(ReplicatedStorage.src.utility.soundHandler)

-- Config
local panelAnimationConfig = require(ReplicatedStorage.src.GameConfiguration.General.panelAnimationConfig)

-- Essentials
local uiSounds = SoundService:WaitForChild("src"):WaitForChild("Sfx"):WaitForChild("UI")
local scaleName = "AssembleScale"

-->
local PanelAnimations = {
	Config = panelAnimationConfig,
	Runs = {}, -- [panelName]: { Generation, Pieces, Tweens }
}

-- Private Methods
function PanelAnimations:resolve(root: Instance, path: string): { GuiObject }
	local current = { root }
	for _, segment in string.split(path, "/") do
		local nextLevel = {}
		for _, parent in current do
			for _, child in parent:GetChildren() do
				local matches = segment == "*" or child.Name == segment
				if matches and child:IsA("GuiObject") and not self.Config.IgnoredNames[child.Name] then
					table.insert(nextLevel, child)
				end
			end
		end
		current = nextLevel
	end
	return current
end

-- Pieces are hidden with their own UIScale until their turn, so Visible is never touched and
-- buttons that other code shows/hides keep working. A piece with its own UIScale (e.g. a pulse)
-- is left at its scale and only moves.
function PanelAnimations:getScale(piece: GuiObject): UIScale?
	local scale = piece:FindFirstChildOfClass("UIScale")
	if scale and scale.Name ~= scaleName then
		return nil
	end

	if not scale then
		scale = Instance.new("UIScale")
		scale.Name = scaleName
		scale.Parent = piece
	end
	return scale
end

function PanelAnimations:finish(panelName: string)
	local run = self.Runs[panelName]
	if not run then
		return
	end
	self.Runs[panelName] = nil

	for _, tween in run.Tweens do
		tween:Cancel()
	end

	for _, piece in run.Pieces do
		self:settle(piece)
	end
end

function PanelAnimations:settle(piece)
	piece.Instance.AnchorPoint = piece.AnchorPoint
	piece.Instance.Position = piece.Position
	piece.Instance.Rotation = piece.Rotation
	if piece.Scale then
		piece.Scale.Scale = 1
	end
end

-- Scaling grows from the anchor point, so pieces are re-anchored to their centre while they
-- animate (same spot on screen) and put back exactly once they land. Measured at rest, before
-- the piece is scaled down.
function PanelAnimations:getCentre(instance: GuiObject): UDim2
	local shift = (Vector2.new(0.5, 0.5) - instance.AnchorPoint) * instance.AbsoluteSize
	return instance.Position + UDim2.fromOffset(shift.X, shift.Y)
end

function PanelAnimations:play(panel: GuiObject, panelConfig)
	self:finish(panel.Name)

	local style = self.Config.Styles[panelConfig.Style]
	local tweenInfo = TweenInfo.new(style.Duration, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local drop = UDim2.fromOffset(0, -panel.AbsoluteSize.Y * style.Drop)

	-- Homes are captured fresh each open; finish() always leaves pieces at rest beforehand.
	local pieces = {}
	for _, path in panelConfig.Pieces do
		for _, instance in self:resolve(panel, path) do
			table.insert(pieces, {
				Instance = instance,
				AnchorPoint = instance.AnchorPoint,
				Position = instance.Position,
				Centre = self:getCentre(instance),
				Rotation = instance.Rotation,
				Scale = self:getScale(instance),
			})
		end
	end

	-- Top to bottom, left to right.
	table.sort(pieces, function(a, b)
		local posA, posB = a.Instance.AbsolutePosition, b.Instance.AbsolutePosition
		if math.abs(posA.Y - posB.Y) > 2 then
			return posA.Y < posB.Y
		end
		return posA.X < posB.X
	end)

	local run = { Pieces = pieces, Tweens = {} }
	self.Runs[panel.Name] = run

	for index, piece in pieces do
		local instance = piece.Instance
		if piece.Scale then
			piece.Scale.Scale = 0
		end

		task.delay(math.min((index - 1) * style.Stagger, style.MaxStagger), function()
			if self.Runs[panel.Name] ~= run then
				return
			end

			local centre = piece.Centre
			instance.AnchorPoint = Vector2.new(0.5, 0.5)
			instance.Position = centre + drop
			instance.Rotation = piece.Rotation + math.random(-style.Tilt, style.Tilt)

			local move = TweenService:Create(instance, tweenInfo, {
				Position = centre,
				Rotation = piece.Rotation,
			})
			move.Completed:Once(function(state)
				if state == Enum.PlaybackState.Completed then
					self:settle(piece)
				end
			end)
			local tweens = { move }

			if piece.Scale then
				piece.Scale.Scale = style.StartScale
				table.insert(tweens, TweenService:Create(piece.Scale, tweenInfo, { Scale = 1 }))
			end

			for _, tween in tweens do
				table.insert(run.Tweens, tween)
				tween:Play()
			end
		end)
	end
end

function PanelAnimations:playSound(soundName: string?)
	local sound = soundName and uiSounds:FindFirstChild(soundName)
	if not sound then
		return
	end

	soundHandler:play(sound, {
		Parent = SoundService,
		PlayOver = true,
	})
end

-- LifeCycle
function PanelAnimations:Init(_player: Player)
	knit.GetController("PanelController").PanelStateChanged:Connect(function(state)
		local panelConfig = self.Config.Panels[state.PanelName]
		if not panelConfig then
			return
		end

		if not state.Visible then
			self:finish(state.PanelName)
			return
		end

		self:playSound(panelConfig.Sound)
		self:play(utility.getPanel(state.PanelName), panelConfig)
	end)
end

return PanelAnimations
