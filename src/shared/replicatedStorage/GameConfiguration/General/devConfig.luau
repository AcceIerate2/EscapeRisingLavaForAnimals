-- Testing helpers. Everything here only ever runs in Studio, never in a live server.
local DevConfig = {}

--[[
	Clickable test blocks spawned outside your plot's gate, to preview the HUD counter effects.
	Each click changes DataKey by a random amount in Amount (negative for a loss).
]]
DevConfig.TestButtons = {
	Enabled = true,
	Offset = Vector3.new(14, -1.5, -9), -- from the plot's gate (sits on the ground); buttons line up along Z
	Spacing = 6,
	Buttons = {
		{ Label = "+ CASH", DataKey = "Cash", Amount = { 500, 50_000 }, Color = Color3.fromRGB(89, 255, 31) },
		{ Label = "- CASH", DataKey = "Cash", Amount = { -50_000, -500 }, Color = Color3.fromRGB(255, 63, 69) },
		{ Label = "+ SPEED", DataKey = "Speed", Amount = { 50, 5_000 }, Color = Color3.fromRGB(90, 200, 255) },
		{ Label = "- SPEED", DataKey = "Speed", Amount = { -5_000, -50 }, Color = Color3.fromRGB(255, 120, 60) },
	},
}

return DevConfig
