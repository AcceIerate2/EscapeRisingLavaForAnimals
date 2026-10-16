-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local CollisionHandler = require(ReplicatedStorage.src.utility.CollisionHandler)

-->
local PlayerService = knit.CreateService({
	Name = "PlayerService",
	Client = {},
	DisconnectFunctions = {},
	CharacterAdded = Signal.new(),
})

-- Private Methods
function PlayerService:load(player: Player)
	if self.DisconnectFunctions[player] or player.Parent ~= Players then
		return
	end
	self.DisconnectFunctions[player] = {}
	local playerDisconnectFunctions = self.DisconnectFunctions[player]

	-- ProfileStoreService
	local profile, profileStoreDisconnectFunction = self.ProfileStoreService:newSession(player)
	if not profile or player.Parent ~= Players or self.DisconnectFunctions[player] ~= playerDisconnectFunctions then
		self.ProfileStoreService:endSession(player)
		self:unload(player)
		return
	end
	playerDisconnectFunctions.profileStoreDisconnectFunction = profileStoreDisconnectFunction

	-- DataService
	self.DataService:ConnectProfile(player, profile.Data)
	playerDisconnectFunctions.dataServiceDisconnectFunction = {
		Function = self.DataService.DisconnectProfile,
		Args = { self.DataService, player },
	}

	-- PlotService
	local plot = self.PlotService:LoadPlot(player)
	if not plot then
		self:unload(player)
		player:Kick("No plots available - Please join another server")
		return
	end
	playerDisconnectFunctions.plotDisconnectFunction = {
		Function = self.PlotService.DisconnectPlot,
		Args = { self.PlotService, player },
	}

	-- TreadmillService
	self.TreadmillService:Load(player, plot)
	playerDisconnectFunctions.treadmillDisconnectFunction = {
		Function = self.TreadmillService.Unload,
		Args = { self.TreadmillService, player },
	}

	-- Gamepasses
	self.MonetizationService:loadGamepasses(player)

	-- BadgeService
	self.BadgeService:awardWelcomeBadges(player)
	if player.Parent ~= Players or self.DisconnectFunctions[player] ~= playerDisconnectFunctions then
		return
	end

	-- CharacterAdded Connection
	local function characterAdded(Character: Model)
		CollisionHandler.ToggleCollisionProperties(Character, {
			CollisionGroup = "PlayerCollisions",
		}, {})

		self.CharacterAdded:Fire(player, Character)
	end

	local characterConnection = player.CharacterAdded:Connect(characterAdded)
	playerDisconnectFunctions.characterDisconnectFunction = {
		Function = function()
			characterConnection:Disconnect()
		end,
		Args = {},
	}
	if player.Character then
		characterAdded(player.Character)
	end

	-- Signal Player is ready
	InstanceCreator("BoolValue", "Synced", player)
end

function PlayerService:unload(player: Player)
	local playerDisconnectFunctions = self.DisconnectFunctions[player]
	if not TypeCheck.table(playerDisconnectFunctions) then
		return
	end
	self.DisconnectFunctions[player] = nil

	for disconnectFunctionName: string, data in pairs(playerDisconnectFunctions) do
		local functionToCall = data["Function"]
		assert(typeof(functionToCall) == "function", `{disconnectFunctionName} does not have a function to call`)

		local args = data["Args"]
		assert(TypeCheck.table(args), "Args must be a table")

		local success, err = pcall(functionToCall, table.unpack(args))
		if not success then
			warn(`Failed to clean up {disconnectFunctionName} for {player.Name}: {err}`)
		end
	end
end

-- LifeCycle
function PlayerService:KnitInit()
	self.ProfileStoreService = knit.GetService("ProfileStoreService")
	self.DataService = knit.GetService("DataService")
	self.MonetizationService = knit.GetService("MonetizationService")
	self.BadgeService = knit.GetService("BadgeService")
	self.PlotService = knit.GetService("PlotService")
	self.TreadmillService = knit.GetService("TreadmillService")
end

function PlayerService:KnitStart()
	-- Player Connections
	Players.PlayerAdded:Connect(function(player: Player)
		self:load(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:unload(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:load(player)
		end)
	end

	-- if the server shuts down
	game:BindToClose(function()
		local playersInServer = Players:GetPlayers()
		for _, player in pairs(playersInServer) do
			self:unload(player)
		end
	end)
end

return PlayerService
