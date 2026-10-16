local WalkSpeedConfig = {}

--[[
	Turns the Speed stat (which grows into the millions) into a sane Humanoid.WalkSpeed.

	WalkSpeed = Base + MaxBonus * (1 - 1 / (1 + decades / HalfDecades))
	where decades = log10(1 + Speed / Start)

	Every 10x more Speed adds less and less, and WalkSpeed never goes past Base + MaxBonus.
	(Trails don't change WalkSpeed; they multiply treadmill Speed gains instead.)

	With the values below:
	  Speed 0 → 16 · 100 → ~28 · 1K → ~38 · 10K → ~46 · 1M → ~55 · 1B → ~62 · cap 80
]]
WalkSpeedConfig.Base = 16 -- WalkSpeed at 0 Speed
WalkSpeedConfig.MaxBonus = 64 -- most WalkSpeed Speed can ever add
WalkSpeedConfig.Start = 25 -- Speed around which the curve starts to bend
WalkSpeedConfig.HalfDecades = 3 -- 10x steps of Speed (past Start) to reach half of MaxBonus

function WalkSpeedConfig.ToWalkSpeed(speed: number): number
	local decades = math.log10(1 + math.max(speed, 0) / WalkSpeedConfig.Start)
	local share = 1 - 1 / (1 + decades / WalkSpeedConfig.HalfDecades)
	return WalkSpeedConfig.Base + WalkSpeedConfig.MaxBonus * share
end

return WalkSpeedConfig
