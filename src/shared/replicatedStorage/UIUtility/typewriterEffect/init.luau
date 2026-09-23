-- Roblox Servicecs
local LocalizationService = game:GetService("LocalizationService")
local Players = game:GetService("Players")

-- Utility
local utility = require(script.Parent.utility)

-- Config
local SOURCE_LOCALE = "en"
local translator = nil

-->
local AnimateUI = {}

function AnimateUI.loadTranslator()
	pcall(function()
		translator = LocalizationService:GetTranslatorForPlayerAsync(Players.LocalPlayer)
	end)
	if not translator then
		pcall(function()
			translator = LocalizationService:GetTranslatorForLocaleAsync(SOURCE_LOCALE)
		end)
	end
end

function AnimateUI.typeWrite(guiObject, text, delayBetweenChars, callback)
	guiObject.Visible = true
	guiObject.AutoLocalize = false
	local displayText = text

	-- Translate text if possible
	if translator then
		displayText = translator:Translate(guiObject, text)
	end

	-- Replace line break tags so grapheme loop will not miss those characters
	displayText = displayText:gsub("<br%s*/>", "\n")
	-- Remove RichText tags since char-by-char animation will break the tags
	displayText = displayText:gsub("<[^<>]->", "")

	-- Set translated/modified text on parent
	utility.updateText(guiObject, text)

	local index = 0
	for first, last in utf8.graphemes(displayText) do
		index += 1
		guiObject.MaxVisibleGraphemes = index

		local childTextLabel = guiObject:FindFirstChildOfClass("TextLabel")
		if childTextLabel then
			childTextLabel.MaxVisibleGraphemes = index
		end

		if typeof(callback) == "function" then
			callback()
		end

		task.wait(delayBetweenChars)
	end
end

return AnimateUI
