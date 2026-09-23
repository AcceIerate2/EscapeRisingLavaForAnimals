local InstanceCreator = require(script.Parent.InstanceCreator)
local Beams = {}

export type BeamObject = {
	Beam: Beam,
	Base: BasePart,
	Target: BasePart,
}

export type BeamHandlerType = {
	Init: (Name: string, BeamTemplate: Beam) -> BeamHandlerType,
	Connect: (self: BeamHandlerType, Base: BasePart, Target: BasePart) -> (),
	Disconnect: (self: BeamHandlerType) -> (),
	Destroy: (self: BeamHandlerType) -> (),
}

local Module = {} :: BeamHandlerType
Module.__index = Module

function Module.Init(Name: string, BeamTemplate: Beam): BeamHandlerType
	local self = setmetatable({}, Module)
	self.Beam = BeamTemplate:Clone()
	self.Beam.Name = Name
	Beams[Name] = self
	self.Beam.Parent = workspace
	return self
end

function Module:Connect(Base: BasePart, Target: BasePart)
	local BeamAttachment0: Attachment
	local BeamAttachment1: Attachment

	for _Index: number, Attachment in pairs(Base:GetChildren()) do
		local IsBeamAttachment = Attachment:HasTag("BeamAttachment")
		if IsBeamAttachment then
			BeamAttachment0 = Attachment
			break
		end
	end

	for _Index: number, Attachment in pairs(Target:GetChildren()) do
		local IsBeamAttachment = Attachment:HasTag("BeamAttachment")
		if IsBeamAttachment then
			BeamAttachment1 = Attachment
			break
		end
	end

	if not BeamAttachment0 then
		BeamAttachment0 = InstanceCreator("Attachment", "BeamAttachment", Base) :: Attachment
		if BeamAttachment0 then
			BeamAttachment0:AddTag("BeamAttachment")
		end
	end

	if not BeamAttachment1 then
		BeamAttachment1 = InstanceCreator("Attachment", "BeamAttachment", Target) :: Attachment
		if BeamAttachment1 then
			BeamAttachment1:AddTag("BeamAttachment")
		end
	end

	self.Base = Base
	self.Target = Target

	self.Beam.Attachment0 = BeamAttachment0
	self.Beam.Attachment1 = BeamAttachment1

	self.Beam.Enabled = true

	self.State = "Connected"
end

function Module:Disconnect()
	if self.Beam.Attachment0 then
		self.Beam.Attachment0:Destroy()
		self.Beam.Attachment0 = nil
	end
	if self.Beam.Attachment1 then
		self.Beam.Attachment1:Destroy()
		self.Beam.Attachment1 = nil
	end
	self.Base = nil
	self.Target = nil

	self.Beam.Enabled = false

	self.State = "Idle"
end

function Module:Destroy()
	if self.State == "Connected" then
		self:Disconnect()
	end
	Beams[self.Beam.Name] = nil
	self.Beam:Destroy()
	setmetatable(self, nil)
	self = nil
end

return Module :: BeamHandlerType
