local RebirthConfig = {}

--[[
	Rebirth N+1 needs: Speed >= round(SpeedBase * SpeedGrowth ^ N)
	Money multiplier after N rebirths: 1 + MultiplierPerRebirth * N
	Requirements are checks, not costs; Reset lists what a rebirth sets back.
]]
RebirthConfig.SpeedBase = 750
RebirthConfig.SpeedGrowth = 3.5
RebirthConfig.MultiplierPerRebirth = 0.5
RebirthConfig.MaxRebirths = 0 -- 0 = unlimited

RebirthConfig.Reset = {
	Speed = 0,
	Cash = 0,
}

-- Skip Rebirth: a Developer Product that grants a rebirth without the requirement and keeps Speed.
-- 0 = not set up yet (the button tells the player it's coming soon).
RebirthConfig.SkipProductId = 0

RebirthConfig.RequestCooldown = 1 -- seconds between rebirth requests per player

-- Public Methods
function RebirthConfig.GetRequirement(rebirths: number): number
	return math.round(RebirthConfig.SpeedBase * RebirthConfig.SpeedGrowth ^ rebirths)
end

function RebirthConfig.GetMultiplier(rebirths: number): number
	return 1 + RebirthConfig.MultiplierPerRebirth * rebirths
end

function RebirthConfig.IsMaxed(rebirths: number): boolean
	return RebirthConfig.MaxRebirths > 0 and rebirths >= RebirthConfig.MaxRebirths
end

return RebirthConfig
