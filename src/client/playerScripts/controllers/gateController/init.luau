-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local Spring = require(ReplicatedStorage.src.utility.Spring)

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
		Direction = 0,
		TargetAngle = 0,
		SpringValue = Instance.new("NumberValue"),
	}

	-- Spring the angle so both leaves stay on their hinge arcs throughout the swing.
	gate.SpringConnection = gate.SpringValue.Changed:Connect(function(angle: number)
		self:poseLeaf(gate.Left, gate.Normal, angle)
		self:poseLeaf(gate.Right, gate.Normal, angle)
	end)

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

		Spring.stop(gate.SpringValue)
		gate.SpringConnection:Disconnect()
		gate.SpringValue:Destroy()

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

function GateController:updateTargets()
	local character = self.Player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	for _, gate in pairs(self.Gates) do
		if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
			gate.Direction = 0
			continue
		end

		local offset = root.Position - gate.Center
		local flatOffset = horizontal(offset)
		local distance = flatOffset.Magnitude

		if math.abs(offset.Y) > self.Config.MaxHeightDifference or distance > self.Config.CloseDistance then
			gate.Direction = 0
		elseif gate.Direction == 0 and distance <= self.Config.OpenDistance then
			local movement = horizontal(humanoid.MoveDirection)
			local crossing = movement:Dot(gate.Normal)

			-- Ignore players walking alongside the gate or away from it.
			if math.abs(crossing) > 0.1 and movement:Dot(flatOffset) <= 0.1 then
				gate.Direction = if crossing > 0 then 1 else -1
			end
		end
	end
end

function GateController:animateGates()
	for _, gate in pairs(self.Gates) do
		local target = math.rad(self.Config.OpenAngle) * gate.Direction
		if gate.TargetAngle == target then
			continue
		end

		gate.TargetAngle = target
		Spring.target(gate.SpringValue, self.Config.SpringDamping, self.Config.SpringFrequency, {
			Value = target,
		})
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
			self:updateTargets()
		end

		self:animateGates()
	end)
end

return GateController
