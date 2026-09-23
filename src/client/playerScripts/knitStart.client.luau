-- Roblox Services
local GamepadService = game:GetService("GamepadService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)

-- Modules
local userInterface = require(script.Parent.userInterface)

-->
knit.AddControllers(script.Parent.controllers)

--
require(script.Parent.clientPreStart)()

-- Wait for services
Players.LocalPlayer:WaitForChild("Synced")

-- start client knit
knit:Start()
	:andThen(function()
		print("Client Knit Started.")
		userInterface()
		--[[GamepadService:EnableGamepadCursor()]]

		InstanceCreator("BoolValue", "ClientReady", Players.LocalPlayer)
	end)
	:catch(warn)
