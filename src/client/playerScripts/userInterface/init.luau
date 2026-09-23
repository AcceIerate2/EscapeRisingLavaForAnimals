-- Roblox Services
local Players = game:GetService("Players")

-- Essentials
local player = Players.LocalPlayer

-- Modules
local buttons = require(script.buttons)
local setup = require(script.setup)

-->
return function()
	player:WaitForChild("Synced")
	print("Server Loaded.")
	setup:Init(player)
	buttons:Init(player)
end
