-- Roblox Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Utility
local TypeCheck = require(ReplicatedStorage.src.utility.TypeCheck)

-- Essentials
local player
local playerGui

if RunService:IsClient() then
	player = Players.LocalPlayer
	playerGui = player.PlayerGui
end

-->
local Utility = {}

function Utility.waitForDescendant(parent: Instance, className: string?, props: { [string]: any }, timeout: number?)
	timeout = timeout or math.huge
	local start = os.clock()

	local function matches(inst: Instance)
		if className and not inst:IsA(className) then
			return false
		end

		for prop, value in pairs(props) do
			if inst[prop] ~= value then
				return false
			end
		end

		return true
	end

	for _, inst in parent:GetDescendants() do
		if matches(inst) then
			return inst
		end
	end

	while os.clock() - start < timeout do
		local inst = parent.DescendantAdded:Wait()

		if matches(inst) then
			return inst
		end
	end

	return nil
end

if RunService:IsClient() then
	function Utility.getPanel(name: string)
		assert(TypeCheck.string(name), "name must be a string")

		local panelsScreenGui = playerGui:WaitForChild("Panels")
		local panelToReturn = panelsScreenGui:WaitForChild(name, 10)
		if not TypeCheck.Instance(panelToReturn) then
			warn(`Are you sure Panel: {name} exists? - userInterface:setup:utility:getPanel`)
		end

		return panelToReturn
	end
end

function Utility.bindTextToValue(label: TextLabel, valueObject: {}, formatter: (string) -> string) end

function Utility.updateText(label: TextLabel, newText: string)
	if not label then
		return
	end

	if not newText then
		return
	end
	label.Text = newText

	local childLabel = label:FindFirstChildOfClass("TextLabel")
	if not childLabel then
		return
	end
	childLabel.Text = newText
end

function Utility.updateTextColor(label: TextLabel, textColor: Color3)
	if not label then
		return
	end

	if not textColor then
		return
	end

	label.TextColor3 = textColor

	local childLabel = label:FindFirstChildOfClass("TextLabel")
	if not childLabel then
		return
	end
	childLabel.TextColor3 = textColor
end

function Utility.createTween(instance, tweenInfo, props)
	local tween = TweenService:Create(instance, tweenInfo, props)

	local functions = {}
	functions = {
		Play = function()
			tween:Play()
			return functions
		end,

		Cancel = function()
			tween:Cancel()
			return functions
		end,

		Pause = function()
			tween:Pause()
			return functions
		end,

		GetTween = function()
			return functions
		end,

		Completed = function(functionToCall: (...any?) -> ...any?, ...)
			tween.Completed:Wait()
			if typeof(functionToCall) == "function" then
				functionToCall(TypeCheck.table(...) and table.unpack(...))
			end
			return functions
		end,

		Destroy = function(functionToCall: (...any?) -> ...any?, ...)
			tween:Cancel()
			tween:Destroy()
			tween = nil
			if typeof(functionToCall) == "function" then
				functionToCall(TypeCheck.table(...) and table.unpack(...))
			end
		end,
	}

	return functions
end

function Utility.isVisibleInScrollingFrame(scrollingFrame: ScrollingFrame, guiObject: GuiObject): boolean
	if not guiObject.Visible then
		return false
	end

	local viewPos = scrollingFrame.AbsolutePosition
	local viewSize = scrollingFrame.AbsoluteWindowSize

	local objPos = guiObject.AbsolutePosition
	local objSize = guiObject.AbsoluteSize

	local viewLeft = viewPos.X
	local viewRight = viewPos.X + viewSize.X
	local viewTop = viewPos.Y
	local viewBottom = viewPos.Y + viewSize.Y

	local objLeft = objPos.X
	local objRight = objPos.X + objSize.X
	local objTop = objPos.Y
	local objBottom = objPos.Y + objSize.Y

	return objRight > viewLeft and objLeft < viewRight and objBottom > viewTop and objTop < viewBottom
end

return Utility
