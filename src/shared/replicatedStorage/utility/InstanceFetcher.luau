export type InstanceFetcher = {
	getFromAncestor: (ancestor: Instance, instanceName: string, className: string) -> Instance?,
}

-- Utility
local TypeCheck = require(script.Parent.TypeCheck)

-- InstanceFetcher Module
local InstanceFetcherModule = {} :: InstanceFetcher

-- InstanceFetcher Functions
function InstanceFetcherModule.getFromAncestor(ancestor: Instance, instanceName: string, className: string): Instance?
	local validAncestor = TypeCheck.Instance(ancestor) :: boolean
	local validName = TypeCheck.string(instanceName) :: boolean
	local validClass = TypeCheck.string(className) :: boolean

	if not validAncestor then
		error("ancestor was not passed as an Instance or could have been nil")
	end

	if not validName then
		error("instanceName was not passed as a string or could have been nil")
	end

	if not validClass then
		error("className was not passed as a string or could have been nil")
	end

	local SELECTED_INSTANCE: Instance?

	local Descendants = ancestor:GetDescendants()

	for _index: number, childInstance: Instance in pairs(Descendants) do
		local nameMatches: boolean = childInstance.Name == instanceName
		local classMatches: boolean = childInstance.ClassName == className

		if not nameMatches or not classMatches then
			continue
		end

		SELECTED_INSTANCE = childInstance
		break
	end

	return SELECTED_INSTANCE
end

return InstanceFetcherModule
