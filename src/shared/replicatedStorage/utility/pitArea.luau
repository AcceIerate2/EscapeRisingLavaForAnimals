-->
-- The pit's area, from GeneratedMap's attributes, shared by everything that asks "is this in the pit?"
-- (the lava HUD, the night). Returns how far down the pit a position is (0 = rim, 1 = floor), or nil
-- outside it.
--   aboveRim: studs above the rim that still count (jumping on the top pad, falling in)
--   pocketReach: studs past the pit's footprint that count below the rim (safe zone pockets)
return function(map: Instance?, position: Vector3, aboveRim: number, pocketReach: number): number?
	local cframe = map and map:GetAttribute("ReferenceCFrame")
	local size = map and map:GetAttribute("ReferenceSize")
	local depth = map and map:GetAttribute("Depth")
	if not cframe or not size or not depth then
		return nil
	end

	local point = cframe:PointToObjectSpace(position)
	local below = size.Y / 2 - point.Y
	local reach = if below > 2 then pocketReach else 0
	local outside = math.abs(point.X) > size.X / 2 + reach or math.abs(point.Z) > size.Z / 2 + reach
	if outside or below < -aboveRim or below > depth + 10 then
		return nil
	end
	return math.clamp(below / depth, 0, 1)
end
