-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- load all Service Modules
knit.AddServices(ServerStorage.src.services)

-- start knit
knit:Start()
	:andThen(function()
		print("Knit Started.")
	end)
	:catch(warn)
