local PanelAnimationConfig = {}

--[[
	How the pieces of a panel enter when it opens.
	Duration: seconds each piece takes to settle (Back easing, so it overshoots a little).
	Drop: fraction of the panel's height a piece falls from.
	Tilt: max random degrees a piece starts rotated by.
	StartScale: size a piece starts at (1 = full size).
	Stagger / MaxStagger: delay between pieces, capped so big panels never drag on.
]]
PanelAnimationConfig.Styles = {
	Lego = { Duration = 0.42, Drop = 0.12, Tilt = 7, StartScale = 1, Stagger = 0.025, MaxStagger = 0.6 },
	Pop = { Duration = 0.22, Drop = 0.02, Tilt = 0, StartScale = 0.6, Stagger = 0.015, MaxStagger = 0.2 },
	Big = { Duration = 0.3, Drop = 0, Tilt = 10, StartScale = 0.2, Stagger = 0.025, MaxStagger = 0.25 },
}

--[[
	Style: one of the Styles above.
	Sound: optional name of a sound in SoundService.src.Sfx.UI, played on open only.
	Pieces: paths inside the panel that animate. "*" means every child, and a name matches every
	child with that name. Pick pieces that are NOT inside a UIListLayout/UIGridLayout, since those
	layouts lock positions; animate the pieces inside each card instead.
]]
PanelAnimationConfig.Panels = {
	Shop = {
		Style = "Big",
		Sound = "ShopOpen",
		Pieces = {
			"Header",
			"Offers/Title/Label",
			"Offers/DoubleSpeed/Title",
			"Offers/DoubleSpeed/Multiplier",
			"Offers/DoubleSpeed/Art",
			"Offers/DoubleSpeed/Buy",
			"Offers/FeaturedEgg/*",
			"Offers/MysteryEggs/*",
			"Offers/Gamepasses/*",
			"Offers/Speed/*",
			"Offers/Cash/*",
		},
	},

	Trails = {
		Style = "Pop",
		Pieces = { "Header", "TrailList/*/*" },
	},

	Index = {
		Style = "Pop",
		Pieces = { "Header", "SelectedPet", "Rewards", "TotalProgress", "Collection/*/*" },
	},

	Sell = {
		Style = "Pop",
		Pieces = { "Pets/Header", "Pets/Inventory/*/*", "Pets/Footer" },
	},

	Settings = {
		Style = "Pop",
		Pieces = { "Header", "Music", "Sfx", "LowGraphics", "Reset" },
	},

	Rebirth = {
		Style = "Lego",
		Pieces = {
			"Header",
			"Content/Current",
			"Content/UpgradeArrow",
			"Content/Next",
			"Content/ResetWarning",
			"Content/SpeedRequirement",
			"Content/Actions/*",
		},
	},
}

-- Children with these names are backgrounds and never animate, even when matched by "*".
PanelAnimationConfig.IgnoredNames = {
	Studs = true,
	Template = true,
}

return PanelAnimationConfig
