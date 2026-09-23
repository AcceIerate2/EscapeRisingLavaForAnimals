local ViewportUtil = {}

export type Subject = Model | BasePart

export type Options = {
	Padding: number?,
	FOV: number?,
	Yaw: number?,
	Pitch: number?,
	ClearOnSetup: boolean?,
	LightDirection: Vector3?,
}

type ResolvedOptions = {
	Padding: number,
	FOV: number,
	Yaw: number,
	Pitch: number,
	ClearOnSetup: boolean,
	LightDirection: Vector3?,
}

export type Handle = {
	Viewport: ViewportFrame,
	Camera: Camera,
	Clone: PVInstance?,
	Options: ResolvedOptions,

	UpdateModel: (self: Handle, newSubject: Subject) -> (),
	Refit: (self: Handle) -> (),
	Destroy: (self: Handle) -> (),
}

local DEFAULTS: ResolvedOptions = {
	Padding = 1.2,
	FOV = 35,
	Yaw = 35,
	Pitch = -20,
	ClearOnSetup = true,
	LightDirection = nil,
}

local function resolveOptions(opts: Options?): ResolvedOptions
	local o: Options = opts or {}

	local clearOnSetup: boolean
	local cos = o.ClearOnSetup
	if cos == nil then
		clearOnSetup = DEFAULTS.ClearOnSetup
	else
		clearOnSetup = cos
	end

	return {
		Padding = o.Padding or DEFAULTS.Padding,
		FOV = o.FOV or DEFAULTS.FOV,
		Yaw = o.Yaw or DEFAULTS.Yaw,
		Pitch = o.Pitch or DEFAULTS.Pitch,
		ClearOnSetup = clearOnSetup,
		LightDirection = o.LightDirection,
	}
end

local function clearViewport(viewport: ViewportFrame)
	for _, child in ipairs(viewport:GetChildren()) do
		child:Destroy()
	end
end

local function ensureCamera(viewport: ViewportFrame, fov: number): Camera
	local cam = viewport.CurrentCamera
	if cam == nil then
		cam = Instance.new("Camera")
		cam.Name = "ViewportCamera"
		cam.Parent = viewport
		viewport.CurrentCamera = cam
	end
	cam.FieldOfView = fov
	return cam
end

local function stripScripts(root: Instance)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BaseScript") then
			d:Destroy()
		end
	end
end

local function getBounds(subject: Subject): (CFrame, Vector3)
	if subject:IsA("Model") then
		return subject:GetBoundingBox()
	else
		-- BasePart
		return subject.CFrame, subject.Size
	end
end

local function centerBoundsAtOrigin(subject: PVInstance, boundsCf: CFrame)
	local pivot = subject:GetPivot()
	subject:PivotTo(CFrame.new(-boundsCf.Position) * pivot)
end

local function cameraCFrame(yawDeg: number, pitchDeg: number, dist: number): CFrame
	local yaw = math.rad(yawDeg)
	local pitch = math.rad(pitchDeg)

	local x = math.cos(pitch) * math.sin(yaw)
	local y = math.sin(pitch)
	local z = math.cos(pitch) * math.cos(yaw)

	local pos = Vector3.new(x, y, z) * dist
	return CFrame.new(pos, Vector3.zero)
end

local function distanceToFit(viewport: ViewportFrame, size: Vector3, fovDeg: number, padding: number): number
	local w = viewport.AbsoluteSize.X
	local h = viewport.AbsoluteSize.Y
	local aspect = if w > 0 and h > 0 then (w / h) else 1

	local vFov = math.rad(fovDeg)
	local hFov = 2 * math.atan(math.tan(vFov * 0.5) * aspect)

	local halfW = (size.X * 0.5) * padding
	local halfH = (size.Y * 0.5) * padding
	local halfD = (size.Z * 0.5) * padding

	local distW = halfW / math.tan(hFov * 0.5)
	local distH = halfH / math.tan(vFov * 0.5)

	local dist = math.max(distW, distH) + halfD
	return math.max(dist, 0.01) -- allow tiny parts to still fill
end

local function setupInternal(viewport: ViewportFrame, subject: Subject, opts: ResolvedOptions): (PVInstance, Camera)
	if opts.ClearOnSetup then
		clearViewport(viewport)
	end
	if opts.LightDirection then
		viewport.LightDirection = opts.LightDirection
	end

	local cloneInst = subject:Clone()
	cloneInst.Name = "ViewportSubject"
	stripScripts(cloneInst)
	cloneInst.Parent = viewport

	-- Clone is Model or BasePart -> both are PVInstance
	local clone = cloneInst

	local boundsCf, size = getBounds(cloneInst)
	centerBoundsAtOrigin(clone, boundsCf)

	local cam = ensureCamera(viewport, opts.FOV)
	local dist = distanceToFit(viewport, size, cam.FieldOfView, opts.Padding)
	cam.CFrame = cameraCFrame(opts.Yaw, opts.Pitch, dist)

	return clone, cam
end

local HandleMT = {}
HandleMT.__index = HandleMT

function HandleMT:Refit()
	if self.Clone == nil then
		return
	end

	local boundsCf, size = getBounds(self.Clone)
	centerBoundsAtOrigin(self.Clone, boundsCf)

	local dist = distanceToFit(self.Viewport, size, self.Camera.FieldOfView, self.Options.Padding)
	self.Camera.CFrame = cameraCFrame(self.Options.Yaw, self.Options.Pitch, dist)
end

function HandleMT:UpdateModel(newSubject: Subject)
	local clone, cam = setupInternal(self.Viewport, newSubject, self.Options)
	self.Clone = clone
	self.Camera = cam
end

function HandleMT:Destroy()
	if self.Clone then
		self.Clone:Destroy()
	end
	self.Clone = nil
end

function ViewportUtil.Setup(viewport: ViewportFrame, subject: Subject, options: Options?): Handle
	local opts = resolveOptions(options)
	local clone, cam = setupInternal(viewport, subject, opts)

	local handle: Handle = setmetatable({
		Viewport = viewport,
		Camera = cam,
		Clone = clone,
		Options = opts,

		UpdateModel = HandleMT.UpdateModel,
		Refit = HandleMT.Refit,
		Destroy = HandleMT.Destroy,
	}, HandleMT) :: any

	return handle
end

return ViewportUtil
