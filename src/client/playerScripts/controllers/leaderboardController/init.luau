-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local NumberShortner = require(ReplicatedStorage.src.utility.NumberShortner)
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Config
local leaderboardConfig = require(ReplicatedStorage.src.GameConfiguration.Gameplay.leaderboardConfig)

-- Essentials
local player = Players.LocalPlayer
local defaultBadgeColor = Color3.fromRGB(45, 45, 50)
local stripeTransparency = 0.94 -- Every other row gets a faint stripe.

-- Helper Functions
local function headshot(userId: number): string
	return `rbxthumb://type=AvatarHeadShot&id={userId}&w=150&h=150`
end

local function formatTime(seconds: number): string
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

-->
local LeaderboardController = knit.CreateController({
	Name = "LeaderboardController",
	Config = leaderboardConfig,
	Boards = {}, -- [boardName]: { Gui, Rows }
	Snapshot = nil,
})

-- Private Methods
function LeaderboardController:format(boardName: string, score: number): string
	local text = NumberShortner(score)
	if self.Config.Boards[boardName].Format == "CashPerSecond" then
		return `${text}/s`
	end
	return text
end

function LeaderboardController:fillRow(row: Frame, boardName: string, rank: number?, userId: number, name: string, score: number)
	row.Rank.Text = if rank then tostring(rank) elseif score > 0 then `{self.Config.DisplayCount}+` else "--"
	row.Rank.BackgroundColor3 = rank and self.Config.RankColors[rank] or defaultBadgeColor
	row.Avatar.Image = headshot(userId)
	row.PlayerName.Text = name
	row.Value.Text = self:format(boardName, score)
end

function LeaderboardController:createBoard(template: SurfaceGui, boardName: string, board)
	local gui = template:Clone()
	gui.Name = `Leaderboard_{boardName}`
	gui.Enabled = true

	gui.Header.Title.Text = board.Title
	gui.Header.Accent.BackgroundColor3 = board.AccentColor
	gui.Footer.MyStats.Edge.BackgroundColor3 = board.AccentColor
	gui.Footer.MyStats.Value.TextColor3 = board.AccentColor

	local rowTemplate = gui.List.Template
	rowTemplate.Value.TextColor3 = board.AccentColor
	self:fillRow(gui.Footer.MyStats, boardName, nil, player.UserId, player.DisplayName, 0)

	gui.Parent = player.PlayerGui
	self.Boards[boardName] = { Gui = gui, RowTemplate = rowTemplate, Rows = {} }
end

-- Board parts stream in and out, so the GUIs are re-attached whenever their UiPart is around.
function LeaderboardController:bindAdornees()
	local folder = workspace:FindFirstChild("Leaderboards")
	for boardName, board in self.Boards do
		local adornee = board.Gui.Adornee
		if adornee and adornee:IsDescendantOf(workspace) then
			continue
		end

		local model = folder and folder:FindFirstChild(boardName)
		board.Gui.Adornee = model and model:FindFirstChild("UiPart")
	end
end

function LeaderboardController:renderBoard(boardName: string, entries)
	local board = self.Boards[boardName]
	local list = board.Gui.List

	for index, entry in entries do
		local row = board.Rows[index]
		if not row then
			row = board.RowTemplate:Clone()
			row.Name = `Row{index}`
			row.LayoutOrder = index
			row.BackgroundTransparency = if index % 2 == 1 then stripeTransparency else 1
			row.Visible = true
			row.Parent = list
			board.Rows[index] = row
		end

		self:fillRow(row, boardName, index, entry.UserId, entry.Name, entry.Score)
		row.Visible = true
	end

	for index = #entries + 1, #board.Rows do
		board.Rows[index].Visible = false
	end

	list.Empty.Visible = #entries == 0
end

function LeaderboardController:render(snapshot)
	if not TypeCheck.table(snapshot) then
		return
	end

	self.Snapshot = snapshot
	for boardName in self.Boards do
		self:renderBoard(boardName, snapshot.Boards[boardName] or {})
	end
end

function LeaderboardController:renderMyStats(stats)
	if not TypeCheck.table(stats) then
		return
	end

	for boardName, board in self.Boards do
		local mine = stats[boardName]
		if mine then
			self:fillRow(board.Gui.Footer.MyStats, boardName, mine.Rank, player.UserId, player.DisplayName, mine.Score)
		end
	end
end

function LeaderboardController:updateCountdown()
	local nextRefresh = self.Snapshot and self.Snapshot.NextRefresh or 0
	local secondsLeft = math.ceil(nextRefresh - workspace:GetServerTimeNow())
	local text = if secondsLeft > 0 then `REFRESH {formatTime(secondsLeft)}` else "REFRESHING..."

	for _, board in self.Boards do
		board.Gui.Header.Countdown.Text = text
	end
end

function LeaderboardController:requestMyStats()
	self.LeaderboardService
		:GetMyStats()
		:andThen(function(stats)
			self:renderMyStats(stats)
		end)
		:catch(warn)
end

-- LifeCycle
function LeaderboardController:KnitInit()
	self.LeaderboardService = knit.GetService("LeaderboardService")
end

function LeaderboardController:KnitStart()
	local template = player:WaitForChild("PlayerGui"):WaitForChild("LeaderboardTemplate")
	for boardName, board in self.Config.Boards do
		self:createBoard(template, boardName, board)
	end
	self:bindAdornees()

	self.LeaderboardService.SnapshotUpdated:Connect(function(snapshot)
		self:render(snapshot)
	end)
	self.LeaderboardService
		:GetSnapshot()
		:andThen(function(snapshot)
			self:render(snapshot)
		end)
		:catch(warn)

	-- Once a second: countdown text and re-attaching streamed boards.
	task.spawn(function()
		local elapsed = self.Config.SampleSeconds
		while true do
			self:bindAdornees()
			self:updateCountdown()

			elapsed += 1
			if elapsed >= self.Config.SampleSeconds then
				elapsed = 0
				self:requestMyStats()
			end
			task.wait(1)
		end
	end)
end

return LeaderboardController
