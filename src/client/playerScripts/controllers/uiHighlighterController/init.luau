-- Roblox Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Signal = require(ReplicatedStorage.src.Packages.Signal)
local knit = require(ReplicatedStorage.src.Packages.knit)

-->
local UIHighlighterController = knit.CreateController({
	Name = "UIHighlighterController",
	DrawSignal = Signal.new(),
	DestroySignal = Signal.new(),
})

-- Public Methods
function UIHighlighterController:Draw(
	config: {
		AbsoluteSize: Vector2,
		AbsolutePosition: Vector2,
		Padding: number?,
	},
	returnDisconnectMethod: boolean?
)
	self.DrawSignal:Fire(config)

	if not returnDisconnectMethod then
		return
	end

	return {
		Disconnect = function()
			UIHighlighterController:destroy()
		end,
	}
end

function UIHighlighterController:Destroy()
	self.DestroySignal:Fire()
end

return UIHighlighterController
