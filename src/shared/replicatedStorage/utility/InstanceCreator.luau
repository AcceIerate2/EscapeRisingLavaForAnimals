-- Roblox Services
local RunService = game:GetService("RunService")

-- Utility
local TypeCheck = require(script.Parent.TypeCheck)

-->
return function(Class: string, Name: string, Parent: Instance, Props: { [string]: any }?): Instance | nil
	if TypeCheck.string(Class) == false then
		error("Argument 'Class' is nil or not passed!")
	end

	local Object = Instance.new(Class) :: Instance
	if Object then
		if TypeCheck.string(Name) == true then
			Object.Name = Name
		end
		if TypeCheck.Instance(Parent) == true then
			Object.Parent = Parent
		end
	elseif Object == nil then
		error("Passed Argument 'Class' is not a valid ClassName!")
	end

	local propsGiven = TypeCheck.table(Props)
	if not propsGiven then
		return Object
	end

	local function addTags(tags)
		for _, tag: string in pairs(tags) do
			Object:AddTag(tag)
		end
	end

	local function addAttributes(attributes: { [string]: any })
		if not TypeCheck.table(attributes) then
			return
		end
		for attributeName: string, value: any in pairs(attributes) do
			Object:SetAttribute(attributeName, value)
		end
	end

	for propName: string, propValue: any in pairs(Props :: { [string]: any }) do
		if propName == "Tags" then
			addTags(propValue)
			continue
		elseif propName == "Attributes" then
			addAttributes(propValue)
			continue
		end

		local ok, err = pcall(function()
			Object[propName] = propValue
		end)

		if not ok and RunService:IsStudio() then
			warn(err)
		end
	end

	return Object
end
