-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility Modules
local deepCopyDict = require(ReplicatedStorage.src.utility.deepCopyDict)

--
local Methods = script.Methods:GetChildren()

-->
local ValueObject = {}

function ValueObject._resolveTarget(root: { [any]: any }, directory: string | { any }?, createMissing: boolean)
	if directory == nil then
		return root
	end

	local current = root
	local pathParts

	if type(directory) == "string" then
		pathParts = string.split(directory, ".")
	elseif type(directory) == "table" then
		pathParts = directory
	else
		error("directory must be nil, a string path, or a table of path parts")
	end

	for _, key in ipairs(pathParts) do
		local nextValue = current[key]

		if nextValue == nil then
			if createMissing then
				nextValue = {}
				current[key] = nextValue
			else
				return nil
			end
		elseif typeof(nextValue) ~= "table" then
			error(`ResolveTarget failed: "{tostring(key)}" is not a table`)
		end

		current = nextValue
	end

	return current
end

function ValueObject:Create(
	name,
	value,
	profileStoreDataConnection,
	updateClient: (
		key: string,
		newValue: any?,
		customData: {
			Key: string,
			NewValue: any?,
		}?
	) -> ()
)
	local bindableEvent = Instance.new("BindableEvent")

	local valueObjectTable = {
		Key = name,
		Value = value,
		Profile = profileStoreDataConnection,
		BindableEvent = bindableEvent,
		Changed = bindableEvent.Event,
		UpdateClient = updateClient,
		DeepCopyDict = deepCopyDict,
		ResolveTarget = ValueObject._resolveTarget,
	}

	for _, moduleScript in ipairs(Methods) do
		if not moduleScript:IsA("ModuleScript") then
			continue
		end

		local methodData = require(moduleScript)
		if not methodData.IsSupported(value) then
			continue
		end

		valueObjectTable[methodData.Key] = methodData.Function
	end

	return valueObjectTable
end

return ValueObject
