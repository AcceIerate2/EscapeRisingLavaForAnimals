-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Essentials
camera = workspace.CurrentCamera

-- Helpers
local CreateTween = TweenService.Create

-->
local CameraController = knit.CreateController({
	Name = "CameraController",
	renderStepName = "cameraLock",
	viewportSizeChanged = Signal.new(),
})

-- Public Methods
function CameraController:UpdateFov(newValue: number, tweenInfo: TweenInfo?)
	assert(TypeCheck.number(newValue), "newValue arg must be a number")

	if tweenInfo == nil then
		camera.FieldOfView = newValue
		return
	end

	CreateTween(TweenService, camera, tweenInfo, {
		FieldOfView = newValue,
	}):Play()
end

function CameraController:LockCameraTo(placeholder: BasePart)
	assert(TypeCheck.Instance(placeholder), "placeholder arg must be a BasePart")
	camera.CameraType = Enum.CameraType.Fixed
	camera.CFrame = placeholder.CFrame
	RunService:BindToRenderStep(self.renderStepName, 0, function()
		camera.CFrame = placeholder.CFrame
	end)
end

function CameraController:UpdateSubject(subject: BasePart)
	assert(TypeCheck.Instance(subject), "subject arg must be a BasePart")
	camera.CameraSubject = subject
end

function CameraController:Reset(subject: BasePart)
	RunService:UnbindFromRenderStep(self.renderStepName)
	camera.CameraType = Enum.CameraType.Custom

	if not TypeCheck.Instance(subject) then
		return
	end
	self:updateSubject(subject)
end

-- LifeCycle
function CameraController:KnitInit()
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		self.viewportSizeChanged:Fire(camera.ViewportSize)
	end)
end

return CameraController
