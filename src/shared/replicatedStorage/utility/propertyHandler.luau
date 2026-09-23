-- Roblox Services
local RunService = game:GetService("RunService")

-->
local PropertyHandler = {}

function PropertyHandler.assignPropertyValues(instance: Instance, props: { [string]: any })
	assert(instance and instance:IsA("Instance"), "instance arg must be an Instance")
	assert(typeof(props) == "table", "values arg must be a table")

	local function addTags(tags)
		for _, tag: string in pairs(tags) do
			instance:AddTag(tag)
		end
	end

	for propName: string, propValue: any in pairs(props :: { [string]: any }) do
		if propName == "Tags" then
			addTags(propValue)
			continue
		end

		local ok, err = pcall(function()
			instance[propName] = propValue
		end)

		if not ok and RunService:IsStudio() then
			warn(err)
		end
	end
end

return PropertyHandler
