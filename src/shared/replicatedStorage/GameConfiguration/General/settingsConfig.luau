local SettingsConfig = {}

--[[
	Player settings, saved in player data under Settings.
	Type: "Volume" (0-1 slider) or "Toggle" (on/off switch).
	Row: the row in Panels.Settings that controls it.
	Default: the value new players start with and "Reset to Default" restores.
]]
SettingsConfig.Settings = {
	Music = { Type = "Volume", Row = "Music", Default = 0.6 },
	Sfx = { Type = "Volume", Row = "Sfx", Default = 0.8 },
	LowGraphics = { Type = "Toggle", Row = "LowGraphics", Default = false },
}

-- Public Methods
function SettingsConfig.GetDefaults(): { [string]: any }
	local defaults = {}
	for key, setting in SettingsConfig.Settings do
		defaults[key] = setting.Default
	end
	return defaults
end

-- Which SoundService.src folders each volume controls.
SettingsConfig.SoundGroups = {
	Music = "Music",
	Sfx = "Sfx",
}

return SettingsConfig
