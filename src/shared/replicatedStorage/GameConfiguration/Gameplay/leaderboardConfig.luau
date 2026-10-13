-- Helpers
local function rgb(r: number, g: number, b: number): Color3
	return Color3.fromRGB(r, g, b)
end

-->
local LeaderboardConfig = {}

LeaderboardConfig.StoreVersion = "v1" -- Changing it starts every board fresh (player data is untouched).
LeaderboardConfig.DisplayCount = 50 -- Rows per board (max 100).
LeaderboardConfig.SampleSeconds = 10 -- How often live scores (and "Your Place") update.
LeaderboardConfig.SaveSeconds = 60 -- How often changed scores are written to the global boards.
LeaderboardConfig.RefreshSeconds = 120 -- How often the global rankings are re-read.

--[[
	Keys must match the models in Workspace.Leaderboards (each needs a UiPart).
	DataKey: player data value the score comes from. Boards without one stay empty until a service
	calls LeaderboardService:RegisterScoreProvider(boardName, function(player) return score end).
	Format: "Number" (1.5M) or "CashPerSecond" ($1.5M/s).
	AccentColor: the board's one (muted) colour: the bar under the title, the scores, and the
	edge of "Your Place". Everything else stays black/white/grey.
]]
LeaderboardConfig.Boards = {
	TopGrabs = {
		Title = "TOP GRABS",
		Format = "Number",
		DataKey = "Grabs",
		AccentColor = rgb(205, 170, 80),
	},
	CashPerSecond = {
		Title = "TOP CASH/S",
		Format = "CashPerSecond",
		AccentColor = rgb(120, 185, 90),
	},
	Speed = {
		Title = "TOP SPEED",
		Format = "Number",
		DataKey = "Speed",
		AccentColor = rgb(95, 170, 205),
	},
}

-- Rank tile colours for the top three (muted gold / silver / bronze).
LeaderboardConfig.RankColors = {
	[1] = rgb(190, 155, 45),
	[2] = rgb(145, 150, 160),
	[3] = rgb(150, 95, 55),
}

return LeaderboardConfig
