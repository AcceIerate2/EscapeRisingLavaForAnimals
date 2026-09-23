local HttpService = game:GetService("HttpService")
local TypeCheck = require(script.Parent.TypeCheck)
local Module = {}

function Module.Insert(Json: string, IndexName: string | number | nil, DataToBeInserted: {} | string): string | nil
	local Decoded = HttpService:JSONDecode(Json)
	if TypeCheck.table(Decoded) then
		if IndexName == nil then
			table.insert(Decoded, DataToBeInserted)
		elseif TypeCheck.string(IndexName) or TypeCheck.number(IndexName) then
			Decoded[IndexName] = DataToBeInserted
		end
		return HttpService:JSONEncode(Decoded)
	end
	return nil
end

function Module.Remove(Json: string, IndexToRemove: number | string | nil, ValueToRemove: any? | nil): string | nil
	local Decoded = HttpService:JSONDecode(Json)
	if TypeCheck.table(Decoded) then
		if IndexToRemove then
			if TypeCheck.number(IndexToRemove) then
				table.remove(Decoded, tonumber(IndexToRemove))
			elseif TypeCheck.string(IndexToRemove) then
				Decoded[IndexToRemove] = nil
			end
		elseif ValueToRemove then
			local FoundIndex = nil :: number | nil
			for _Index, Value in ipairs(Decoded) do
				if Value == ValueToRemove then
					FoundIndex = _Index
					break
				end
			end
			if TypeCheck.number(FoundIndex) then
				table.remove(Decoded, FoundIndex)
			end
		end
		return HttpService:JSONEncode(Decoded)
	end
	return nil
end

function Module.StringExists(Json: string, Value: string): boolean
	local Decoded = HttpService:JSONDecode(Json) :: {}
	if TypeCheck.table(Decoded) then
		for _Index, _Value: any in pairs(Decoded) do
			if _Value == Value then
				return true
			end
		end
	end
	return false
end

return Module
