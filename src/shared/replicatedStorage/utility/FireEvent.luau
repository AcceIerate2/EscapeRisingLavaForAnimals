export type FireEvent = {
	fireRemoteEvent: (name: string, ...any) -> RemoteEvent?,
	fireBindableEvent: (name: string, ...any) -> BindableEvent?,
	fireRemoteFunction: (name: string, ...any) -> (RemoteFunction, ...any),
}

-- Default Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Utility
local TypeCheck = require(script.Parent.TypeCheck)

-- Folders
local Events = ReplicatedStorage:WaitForChild("Events") :: Folder & { Folder }
local RemoteEvents = Events:WaitForChild("RemoteEvents") :: Folder & { RemoteEvent }
local BindableEvents = Events:WaitForChild("BindableEvents") :: Folder & { BindableEvent }
local RemoteFunctions = Events:WaitForChild("RemoteFunctions") :: Folder & { RemoteFunction }

-- FireEvent Module
local FireEventModule = {} :: FireEvent

-- FireEvent Functions
function FireEventModule.fireRemoteEvent(name: string, ...: any): RemoteEvent?
	local validName = TypeCheck.string(name) :: boolean
	if not validName then
		error("name was not a string or could have been nil")
	end

	local remoteEvent = RemoteEvents:FindFirstChild(name) :: RemoteEvent?
	if not remoteEvent or not remoteEvent:IsA("RemoteEvent") then
		error(`Could not find RemoteEvent with name: {name}`)
	end

	local functionName = "FireClient" :: string
	local isClient = RunService:IsClient() :: boolean
	if isClient then
		functionName = "FireServer" :: string
	end

	-- Fire the remote event with the provided arguments
	remoteEvent[functionName](remoteEvent, table.unpack({ ... }))

	return remoteEvent
end

function FireEventModule.fireBindableEvent(name: string, ...: any): BindableEvent?
	local validName = TypeCheck.string(name) :: boolean
	if not validName then
		error("name was not a string or could have been nil")
	end

	local bindableEvent = BindableEvents:FindFirstChild(name) :: BindableEvent?
	if not bindableEvent or not bindableEvent:IsA("BindableEvent") then
		error(`Could not find BindableEvent with name: {name}`)
	end

	bindableEvent:Fire(table.unpack({ ... }))

	return bindableEvent
end

function FireEventModule.fireRemoteFunction(name: string, ...: any): (RemoteFunction, ...any)
	local validName = TypeCheck.string(name) :: boolean
	if not validName then
		error("name was not a string or could have been nil")
	end

	local remoteFunction = RemoteFunctions:FindFirstChild(name) :: RemoteFunction?
	if not remoteFunction or not remoteFunction:IsA("RemoteFunction") then
		error(`Could not find RemoteFunction with name {name}`)
	end

	local functionName = "InvokeClient" :: string
	local isClient = RunService:IsClient() :: boolean
	if isClient then
		functionName = "InvokeServer" :: string
	end

	local results = { remoteFunction[functionName](remoteFunction, table.unpack({ ... })) }
	return remoteFunction, table.unpack(results)
end

return FireEventModule
