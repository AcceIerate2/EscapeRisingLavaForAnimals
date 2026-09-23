-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local knit = require(ReplicatedStorage.src.Packages.knit)

-- Utility Modules
local InstanceCreator = require(ReplicatedStorage.src.utility.InstanceCreator)
local SafeFunctionCaller = require(ReplicatedStorage.src.utility.SafeFunctionCaller)

-->
local DataController = knit.CreateController({
	Name = "DataController",
	Events = {},
	Data = {},
})

-- Public Methods
function DataController:GetValue(valueName: string)
	assert(typeof(valueName) == "string", "valueName arg must be a string")
	local dataToReturn = self.Data[valueName]
	if not dataToReturn then
		repeat
			task.wait()
			dataToReturn = self.Data[valueName]
		until dataToReturn ~= nil
	end
	return dataToReturn
end

function DataController:GetValueChangedSignal(valueName: string)
	local event = self.Events[valueName]

	if not event then
		warn(
			`[DataController] No client signal registered for "{valueName}" yet. Retrying for up to 3 seconds before failing.`
		)
	end

	for _ = 3, 1, -1 do
		event = self.Events[valueName]
		if event then
			break
		end
		task.wait(1)
	end

	assert(
		event,
		`[DataController] Failed to get client signal for "{valueName}" after waiting 3 seconds. Make sure it is created before calling GetValueChangedSignal().`
	)

	return event.Event
end

-- Private Methods
function DataController:connect()
	local valueObjectChangedSignal = self.DataService.ValueObjectChanged
	valueObjectChangedSignal:Connect(
		function(key: string, newValue: any?, customDataChange: { Key: string | number, NewValue: any? })
			local eventToFire: BindableEvent = self.Events[key]
			if not eventToFire then
				return
			end

			if typeof(customDataChange) == "table" then
				newValue = self.Data[key]
				if typeof(newValue) ~= "table" then
					return
				end

				newValue[customDataChange.Key] = customDataChange.NewValue
			end

			eventToFire:Fire(newValue, customDataChange)
			self.Data[key] = newValue
		end
	)
end

function DataController:loadEvents(profileKeys: { string })
	assert(typeof(profileKeys) == "table", "profileKeys arg must be a table")
	for _, valueName: string in pairs(profileKeys) do
		self.Events[valueName] = InstanceCreator("BindableEvent", valueName, script)
		self.DataService
			:GetValue(valueName)
			:andThen(function(data)
				self.Data[valueName] = data
			end)
			:catch(warn)
	end
end

-- LifeCycle
function DataController:KnitInit()
	self.DataService = knit.GetService("DataService")
	local status, keys = SafeFunctionCaller(function()
		local _status, _keys = self.DataService:GetProfileKeys():await()
		assert(typeof(_status) == "boolean" and _status == true, "GetProfileKeys request failed.")
		return _keys
	end)
	assert(
		typeof(status) == "boolean" and status == true or typeof(keys) ~= "table",
		"[SafeFunctionCaller] GetProfileKeys request failed."
	)

	self:loadEvents(keys)
	self:connect()
end

return DataController
