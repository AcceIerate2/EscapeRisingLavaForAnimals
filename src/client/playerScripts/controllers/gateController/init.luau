-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Config
local gatesConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.gatesConfig)

-- Essentials
local UP = Vector3.yAxis

-- Helpers
local function horizontal(vector: Vector3): Vector3
	return Vector3.new(vector.X, 0, vector.Z)
end

-->
local GateController = knit.CreateController({
	Name = "GateController",
	Config = gatesConfig,
	Player = Players.LocalPlayer,
	Gates = {},
})

-- Private Methods
function GateController:makeLeaf(model: Model, outward: Vector3)
	local bounds, size = model:GetBoundingBox()
	local hingeAttachment = model:FindFirstChild("Hinge", true)

	local hingePosition
	if hingeAttachment and hingeAttachment:IsA("Attachment") then
		hingePosition = hingeAttachment.WorldPosition
	else
		-- Project the bounding box onto the doorway's width to find its outer edge.
		local extent = (
			math.abs(bounds.RightVector:Dot(outward)) * size.X
			+ math.abs(bounds.UpVector:Dot(outward)) * size.Y
			+ math.abs(bounds.LookVector:Dot(outward)) * size.Z
		) * 0.5
		hingePosition = bounds.Position + outward * extent
	end

	local hinge = CFrame.new(hingePosition)
	return {
		Model = model,
		ClosedPivot = model:GetPivot(),
		Hinge = hinge,
		Offset = hinge:ToObjectSpace(model:GetPivot()),
		Inward = horizontal(bounds.Position - hingePosition),
	}
end

function GateController:makeGate(model: Model, left: Model, right: Model)
	if not left:FindFirstChildWhichIsA("BasePart", true) or not right:FindFirstChildWhichIsA("BasePart", true) then
		return nil
	end

	local leftBounds = left:GetBoundingBox()
	local rightBounds = right:GetBoundingBox()

	local across = horizontal(rightBounds.Position - leftBounds.Position)
	if across.Magnitude < 0.01 then
		return nil
	end
	across = across.Unit

	local gate = {
		Model = model,
		Left = self:makeLeaf(left, -across),
		Right = self:makeLeaf(right, across),
		Center = (leftBounds.Position + rightBounds.Position) * 0.5,
		Normal = UP:Cross(across),
		Open = false,
		Direction = 1, -- which way it swings: away from the side the player came from
		Angle = 0,
	}
	return gate
end

function GateController:poseLeaf(leaf, normal: Vector3, angle: number)
	-- Opposite signs make both leaves swing toward the same side of the doorway.
	local sign = if UP:Cross(leaf.Inward):Dot(normal) >= 0 then 1 else -1
	leaf.Model:PivotTo(leaf.Hinge * CFrame.Angles(0, angle * sign, 0) * leaf.Offset)
end

function GateController:refreshGates(plots: Instance?)
	local present = {}
	if plots then
		for _, plot in plots:GetChildren() do
			local model = plot:FindFirstChild("Gates")
			local left = model and model:FindFirstChild("Left")
			local right = model and model:FindFirstChild("Right")

			if model and model:IsA("Model") and left and left:IsA("Model") and right and right:IsA("Model") then
				present[model] = { Left = left, Right = right }
			end
		end
	end

	-- Restore surviving leaves before forgetting a removed or replaced gate.
	for model, gate in pairs(self.Gates) do
		local leaves = present[model]
		if leaves and leaves.Left == gate.Left.Model and leaves.Right == gate.Right.Model then
			continue
		end

		for _, leaf in { gate.Left, gate.Right } do
			if leaf.Model.Parent then
				leaf.Model:PivotTo(leaf.ClosedPivot)
			end
		end

		self.Gates[model] = nil
	end

	-- Track newly found gates.
	for model, leaves in pairs(present) do
		if not self.Gates[model] then
			self.Gates[model] = self:makeGate(model, leaves.Left, leaves.Right)
		end
	end
end

-- A gate opens fully while the player is within OpenDistance and closes once they're past
-- CloseDistance. The swing side is picked fresh each time it opens - away from the side the player
-- comes from - so coming back from the other side opens it the new way even mid-close.
function GateController:updateTargets()
	local character = self.Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local config = self.Config

	for _, gate in pairs(self.Gates) do
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
			gate.Open = false
			continue
		end

		local offset = root.Position - gate.Center
		local distance = horizontal(offset).Magnitude
		local inRange = math.abs(offset.Y) <= config.MaxHeightDifference

		if not gate.Open and inRange and distance <= config.OpenDistance then
			gate.Open = true
			gate.Direction = if offset:Dot(gate.Normal) < 0 then 1 else -1
		elseif gate.Open and (not inRange or distance > config.CloseDistance) then
			gate.Open = false
		end
	end
end

-- Leaves swing at a steady speed toward fully open (on the chosen side) or shut.
function GateController:animateGates(deltaTime: number)
	local config = self.Config
	local step = math.rad(config.SwingSpeed) * deltaTime

	for _, gate in pairs(self.Gates) do
		local target = if gate.Open then math.rad(config.OpenAngle) * gate.Direction else 0
		if gate.Angle == target then
			continue
		end

		gate.Angle += math.clamp(target - gate.Angle, -step, step)
		self:poseLeaf(gate.Left, gate.Normal, gate.Angle)
		self:poseLeaf(gate.Right, gate.Normal, gate.Angle)
	end
end

-- LifeCycle
function GateController:KnitStart()
	local elapsed = self.Config.CheckInterval

	RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime

		if elapsed >= self.Config.CheckInterval then
			elapsed = 0

			-- Also discovers plots and gates added later or streamed into the client.
			self:refreshGates(workspace:FindFirstChild("Plots"))
		end

		self:updateTargets()
		self:animateGates(deltaTime)
	end)
end

return GateController
