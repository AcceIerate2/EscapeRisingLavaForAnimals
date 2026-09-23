-- Roblox Services
local CollectionService = game:GetService("CollectionService")

-->
local transparentParts = CollectionService:GetTagged("TransparentPart")
for _, transparentPart: BasePart in pairs(transparentParts) do
	transparentPart.Transparency = 1
	transparentPart.CanCollide = false
	transparentPart.CanQuery = false
	transparentPart.CanTouch = false
end
