local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Events = ReplicatedStorage.Events

local Module = {}

function Module.listenToRemoteEvent(remoteName: string, callback: (...any) -> ...any): RBXScriptConnection
	if not remoteName or not callback then
		error("remoteName or callback was not passed")
	end

	local remoteEvent = Events.RemoteEvents:FindFirstChild(remoteName) :: RemoteEvent
	if not remoteEvent or not remoteEvent:IsA("RemoteEvent") then
		error(`RemoteEvent: {remoteName} does not exist`)
	end

	if RunService:IsClient() then
		return remoteEvent.OnClientEvent:Connect(callback)
	elseif RunService:IsServer() then
		return remoteEvent.OnServerEvent:Connect(callback)
	end

	error("This function can only be used on the client or server.")
end

function Module.listenToBindableEvent(name: string, callback: (...any) -> ...any): RBXScriptConnection
	if not name or not callback then
		error("name or callback was not passed")
	end

	local bindableEvent = Events.BindableEvents:FindFirstChild(name) :: BindableEvent
	if not bindableEvent or not bindableEvent:IsA("BindableEvent") then
		error(`BindableEvent: {name} does not exist`)
	end

	return bindableEvent.Event:Connect(callback)
end

function Module.listenToRemoteFunction(remoteName: string, callback: (...any) -> ...any): nil
	if not remoteName or not callback then
		error(`remoteFunction Name or callback was not passed`)
	end

	local remoteFunction = Events.RemoteFunctions:FindFirstChild(remoteName) :: RemoteFunction
	if not remoteFunction or not remoteFunction:IsA("RemoteFunction") then
		error(`RemoteFunction: {remoteName} does not exist`)
	end

	if RunService:IsClient() then
		remoteFunction.OnClientInvoke = callback
		return
	elseif RunService:IsServer() then
		remoteFunction.OnServerInvoke = callback
		return
	end

	error("This function can only be used on the client or server.")
end

return Module
