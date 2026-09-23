local PlayerService = game:GetService("Players")

local thumbType = Enum.ThumbnailType.HeadShot
local thumbSize = Enum.ThumbnailSize.Size420x420

local function Request(Player: Player | number)
	local UserId = Player
	if typeof(Player) == "Instance" then
		UserId = Player.UserId
	end
	local Status, Response = pcall(function()
		return PlayerService:GetUserThumbnailAsync(UserId, thumbType, thumbSize)
	end)
	if Status == true then
		return Response
	end
	warn(Response)
	task.wait(1.25)
	return Request(Player)
end

return function(Player: Player | number)
	local Response = Request(Player)
	if Response and typeof(Response) == "string" and string.find(Response, "rbxthumb") ~= nil then
		return Response
	end
	return nil
end
