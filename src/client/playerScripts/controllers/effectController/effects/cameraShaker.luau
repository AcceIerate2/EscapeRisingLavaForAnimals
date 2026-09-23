-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local RbxCameraShaker = require(ReplicatedStorage.src.utility.RbxCameraShaker)

-->
local CameraShaker = {}

function CameraShaker._shakeCamera(shakeCFrame)
	workspace.CurrentCamera.CFrame = workspace.CurrentCamera.CFrame * shakeCFrame
end

function CameraShaker:Play(_, props: { [string]: any })
	self.CamShake:Shake(RbxCameraShaker.Presets[props.ShakePreset])
end

function CameraShaker:Init()
	local renderPriority = Enum.RenderPriority.Camera.Value + 1
	self.CamShake = RbxCameraShaker.new(renderPriority, self._shakeCamera)
	self.CamShake:Start()
end

return CameraShaker
