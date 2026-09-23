-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Utility
local utility = require(ReplicatedStorage.src.UIUtility.utility)

-->
local Alerts = {
	CountsByButton = {} :: { [GuiButton]: { Count: number, BadgeUI: Frame & { Txt: TextLabel } } },
	UI = require(script.alertBadgeUI),
}

function Alerts:getButtonData(button)
	if not self.CountsByButton[button] then
		self.CountsByButton[button] = {
			Count = 0,
			BadgeUI = self.UI(button),
		}
	end
	return self.CountsByButton[button]
end

function Alerts:manipulate(button, increment: number)
	local data = self:getButtonData(button)

	local count = data.Count
	count += increment

	utility.updateText(data.BadgeUI.Txt, count)
end

function Alerts:clear(button)
	local data = self:getButtonData(button)
	data.BadgeUI:Destroy()
	self.CountsByButton[button] = nil
end

return Alerts
