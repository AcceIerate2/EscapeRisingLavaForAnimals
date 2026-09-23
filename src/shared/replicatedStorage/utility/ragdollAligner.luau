-- Utility
local InstanceCreator = require(script.Parent.InstanceCreator)
local TypeCheck = require(script.Parent.TypeCheck)

--?
return function(attachment1: Attachment, attachment2: Attachment, parent: Instance)
	assert(TypeCheck.Instance(attachment1) and attachment1:IsA("Attachment"), "attachment1 arg must be an Attachment")
	assert(TypeCheck.Instance(attachment2) and attachment2:IsA("Attachment"), "attachment2 arg must be an Attachment")
	assert(TypeCheck.Instance(parent), "parent arg must be an Instance")

	-- AlignPosition
	local alignPosition = InstanceCreator("AlignPosition", "AlignPosition", parent, {
		Mode = Enum.PositionAlignmentMode.TwoAttachment,
		Attachment0 = attachment1,
		Attachment1 = attachment2,

		MaxForce = math.huge,
		MaxVelocity = math.huge,

		ApplyAtCenterOfMass = true,
		Responsiveness = 200,
		Enabled = true,
	})

	-- AlignOrientation
	local alignOrientation = InstanceCreator("AlignOrientation", "AlignOrientation", parent, {
		Mode = Enum.OrientationAlignmentMode.TwoAttachment,
		Attachment0 = attachment1,
		Attachment1 = attachment2,
		MaxTorque = math.huge,
		Responsiveness = 200,
		Enabled = true,
	})

	return alignPosition, alignOrientation
end
