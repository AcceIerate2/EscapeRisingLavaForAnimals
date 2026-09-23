-- Roblox Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

-- Packages
local profileStore = require(ServerStorage.src.Packages.profileStore)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local ProfileStoreService = knit.CreateService({
	Name = "ProfileStoreService",
	Client = {},
	Profiles = {},
	Config = require(script.config),
})

function ProfileStoreService:getProfile(player: Player)
	return self.Profiles[player]
end

-- create a new profile session
function ProfileStoreService:newSession(player: Player)
	local profile = self.ProfileStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	if not profile then
		player:Kick(`Profile load fail - Please rejoin`)
	end

	profile:AddUserId(player.UserId) -- GDPR Compliance
	profile:Reconcile() -- Fills in missing variables from PROFILE_TEMPLATE

	-- profile session-end cleanup
	profile.OnSessionEnd:Connect(function()
		self.Profiles[player] = nil
		player:Kick(`Profile session ended - Please rejoin`)
	end)

	if player.Parent ~= Players then
		profile:EndSession()
	end

	self.Profiles[player] = profile
	print(`Profile loaded for {player.Name}.`)

	local profileDisconnectFunctionData = {
		["Function"] = self.endSession,
		["Args"] = { self, player },
	}

	return profile, profileDisconnectFunctionData
end

function ProfileStoreService:endSession(player: Player)
	local profile = self.Profiles[player]
	if not profile then
		return
	end

	profile.Data.LastSeen = os.time()
	profile.Data.JoinedBefore = true

	profile:EndSession()
	print(`Ended Profile Session for {player.Name}.`)
end

function ProfileStoreService:KnitInit()
	local profileTemplate = self.Config.DataTemplate

	local profileStoreName = RunService:IsStudio() and HttpService:GenerateGUID(false)
		or HttpService:GenerateGUID(false)
	self.ProfileStore = profileStore.New(profileStoreName, profileTemplate)
end

return ProfileStoreService
