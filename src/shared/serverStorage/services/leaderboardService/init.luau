-- Roblox Services
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)

-- Config
local leaderboardConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.leaderboardConfig)

-- Essentials
local maxScore = 2 ^ 53 - 1

-- Helper Functions
local function toScore(value: any): number
	if typeof(value) ~= "number" or value ~= value then
		return 0
	end
	return math.clamp(math.floor(value), 0, maxScore)
end

-->
local LeaderboardService = knit.CreateService({
	Name = "LeaderboardService",
	Client = {
		SnapshotUpdated = knit.CreateSignal(),
	},
	Config = leaderboardConfig,

	Stores = {},
	Providers = {},
	Scores = {}, -- [Player]: { [boardName]: number } latest sampled scores
	SavedScores = {}, -- [Player]: { [boardName]: number } last written scores
	DisplayNames = {}, -- [userId]: string
	Snapshot = { Boards = {}, NextRefresh = 0 },
})

-- Client Exposed Methods
function LeaderboardService.Client:GetSnapshot(_player: Player)
	return self.Server.Snapshot
end

function LeaderboardService.Client:GetMyStats(player: Player)
	return self.Server:GetMyStats(player)
end

-- Public Methods
function LeaderboardService:RegisterScoreProvider(boardName: string, provider: (Player) -> number)
	assert(self.Config.Boards[boardName], `Unknown leaderboard: {boardName}`)
	assert(TypeCheck["function"](provider), "provider arg must be a function")
	self.Providers[boardName] = provider
end

function LeaderboardService:GetMyStats(player: Player)
	self:sample(player)

	local stats = {}
	local scores = self.Scores[player] or {}

	for boardName in self.Config.Boards do
		local rank = nil
		for index, entry in self.Snapshot.Boards[boardName] or {} do
			if entry.UserId == player.UserId then
				rank = index
				break
			end
		end

		stats[boardName] = {
			Score = scores[boardName] or 0,
			Rank = rank,
		}
	end

	return stats
end

-- Private Methods
function LeaderboardService:getScore(player: Player, boardName: string): number
	local provider = self.Providers[boardName]
	if not provider then
		return 0
	end

	local success, score = pcall(provider, player)
	return if success then toScore(score) else 0
end

function LeaderboardService:sample(player: Player)
	if not self.DataService:GetProfile(player) then
		return
	end

	local scores = self.Scores[player] or {}
	for boardName in self.Config.Boards do
		scores[boardName] = self:getScore(player, boardName)
	end
	self.Scores[player] = scores
end

function LeaderboardService:save(player: Player)
	local scores = self.Scores[player]
	if not scores then
		return
	end

	local saved = self.SavedScores[player] or {}
	self.SavedScores[player] = saved

	for boardName, score in scores do
		-- Zero scores are never written, so empty boards stay clean.
		if score <= 0 or saved[boardName] == score then
			continue
		end

		local budget = DataStoreService:GetRequestBudgetForRequestType(Enum.DataStoreRequestType.SetIncrementSortedAsync)
		if budget <= 0 then
			return
		end

		local success = pcall(self.Stores[boardName].SetAsync, self.Stores[boardName], tostring(player.UserId), score)
		if success then
			saved[boardName] = score
		end
	end
end

function LeaderboardService:resolveNames(userIds: { number })
	local missing = {}
	for _, userId in userIds do
		if not self.DisplayNames[userId] then
			table.insert(missing, userId)
		end
	end

	-- Players in this server are free; everyone else is looked up in one batch.
	for index = #missing, 1, -1 do
		local player = Players:GetPlayerByUserId(missing[index])
		if player then
			self.DisplayNames[player.UserId] = player.DisplayName
			table.remove(missing, index)
		end
	end

	if #missing == 0 then
		return
	end

	local success, infos = SafeFunctionCaller(UserService.GetUserInfosByUserIdsAsync, UserService, missing)
	for _, info in if success and TypeCheck.table(infos) then infos else {} do
		self.DisplayNames[info.Id] = info.DisplayName
	end
end

function LeaderboardService:readBoard(boardName: string)
	local store = self.Stores[boardName]
	local success, pages = pcall(store.GetSortedAsync, store, false, math.clamp(self.Config.DisplayCount, 1, 100))
	if not success then
		return nil
	end

	local entries = {}
	for _, item in pages:GetCurrentPage() do
		local userId = tonumber(item.key)
		if userId then
			table.insert(entries, { UserId = userId, Score = toScore(item.value) })
		end
	end
	return entries
end

function LeaderboardService:refresh()
	local boards = {}
	local userIds = {}

	for boardName in self.Config.Boards do
		-- A failed read keeps the previous rankings instead of blanking the board.
		local entries = self:readBoard(boardName) or self.Snapshot.Boards[boardName] or {}
		boards[boardName] = entries
		for _, entry in entries do
			table.insert(userIds, entry.UserId)
		end
	end

	self:resolveNames(userIds)
	for _, entries in boards do
		for _, entry in entries do
			entry.Name = self.DisplayNames[entry.UserId] or "Player"
		end
	end

	self.Snapshot = {
		Boards = boards,
		NextRefresh = workspace:GetServerTimeNow() + self.Config.RefreshSeconds,
	}
	self.Client.SnapshotUpdated:FireAll(self.Snapshot)
end

function LeaderboardService:startLoop(seconds: number, callback: () -> ())
	task.spawn(function()
		while true do
			task.wait(seconds)
			SafeFunctionCaller(callback)
		end
	end)
end

-- LifeCycle
function LeaderboardService:KnitInit()
	self.DataService = knit.GetService("DataService")

	for boardName, board in self.Config.Boards do
		self.Stores[boardName] = DataStoreService:GetOrderedDataStore(`Leaderboard_{self.Config.StoreVersion}_{boardName}`)

		if board.DataKey then
			self.Providers[boardName] = function(player: Player)
				local profile = self.DataService:GetProfile(player)
				local valueObject = profile and profile[board.DataKey]
				return valueObject and valueObject:Get() or 0
			end
		end
	end
end

function LeaderboardService:KnitStart()
	Players.PlayerRemoving:Connect(function(player: Player)
		-- Data may already be disconnected, so the last sampled scores are saved.
		pcall(self.sample, self, player)
		self:save(player)
		self.Scores[player] = nil
		self.SavedScores[player] = nil
	end)

	self:startLoop(self.Config.SampleSeconds, function()
		for _, player in Players:GetPlayers() do
			self:sample(player)
		end
	end)

	self:startLoop(self.Config.SaveSeconds, function()
		for _, player in Players:GetPlayers() do
			self:save(player)
		end
	end)

	task.spawn(function()
		SafeFunctionCaller(self.refresh, self)
		self:startLoop(self.Config.RefreshSeconds, function()
			self:refresh()
		end)
	end)
end

return LeaderboardService
