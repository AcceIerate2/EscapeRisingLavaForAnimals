-- Modules
local Builder = require(script.Builder)
local DefaultConfig = require(script.Config)
local GeometryValidator = require(script.GeometryValidator)
local PlatformGenerator = require(script.PlatformGenerator)
local RampGenerator = require(script.RampGenerator)
local RoutePlanner = require(script.RoutePlanner)
local SafeZoneGenerator = require(script.SafeZoneGenerator)
local ShaftGenerator = require(script.ShaftGenerator)
local SpawnMarkerGenerator = require(script.SpawnMarkerGenerator)

-->
--[[
	Procedural lava-shaft map, reconstructed from Workspace.TemplateTemplate's geometry. It is a pit
	that hangs below the top of Workspace.Reference (any rotation): the entrance landing is flush
	with the Reference's top and the route winds down from there to the pit floor.

	Usage (Studio command bar / plugin):
		local map, report = require(game.ServerStorage.src.mapGenerator).Generate({ Seed = 42 })

	Regenerating replaces Workspace.GeneratedMap only; TemplateTemplate and Reference are never touched.
	If the Reference has been deleted, the map is rebuilt where the last one was.
]]
local MapGenerator = {}

-- Where the pit goes: Workspace.Reference, or once that's deleted, where the last map was built.
local function findReference()
	for _, descendant in workspace:GetDescendants() do
		if descendant.Name == "Reference" and descendant:IsA("BasePart") then
			return { CFrame = descendant.CFrame, Size = descendant.Size }
		end
	end

	local old = workspace:FindFirstChild("GeneratedMap")
	local cframe = old and old:GetAttribute("ReferenceCFrame")
	local size = old and old:GetAttribute("ReferenceSize")
	if cframe and size then
		return { CFrame = cframe, Size = size }
	end
	error("[MapGenerator] Workspace has no BasePart named Reference and no GeneratedMap to rebuild in place")
end

function MapGenerator.Generate(overrides: { [string]: any }?)
	local config = table.clone(DefaultConfig)
	for key, value in overrides or {} do
		config[key] = value
	end

	local reference = findReference()
	local old = workspace:FindFirstChild("GeneratedMap")
	if old then
		old:Destroy()
	end

	-- Everything is placed relative to the centre of the pit's floor, which is Summit studs below the
	-- centre of the Reference's top surface.
	local route = RoutePlanner.Plan(config)
	local origin = reference.CFrame * CFrame.new(0, reference.Size.Y / 2 - route.Summit, 0)
	local builder = Builder.new(config, origin, Random.new(config.Seed))

	ShaftGenerator.Build(builder, route, reference)
	SafeZoneGenerator.Build(builder, route)
	RampGenerator.Build(builder, route)
	local topZone = PlatformGenerator.BuildTopPad(builder, route)
	builder.TopPad = topZone and topZone.Model
	builder.TopZone = topZone
	local zones = PlatformGenerator.Build(builder, route)
	local allZones = table.clone(zones)
	if topZone then
		table.insert(allZones, 1, topZone)
	end
	SpawnMarkerGenerator.Build(builder, allZones)

	-- Characters below FallenPartsDestroyHeight are killed, so keep it well under the pit floor.
	local floorBottom = builder.Floor.Position.Y - builder.Floor.Size.Y / 2
	local killHeight = math.floor((floorBottom - 100) / 100) * 100
	if workspace.FallenPartsDestroyHeight > killHeight then
		workspace.FallenPartsDestroyHeight = killHeight
	end

	local map = builder.Map
	map:SetAttribute("Seed", config.Seed)
	map:SetAttribute("Laps", config.CircuitCount)
	map:SetAttribute("LapHeight", route.LapHeight)
	map:SetAttribute("Depth", route.Summit)
	map:SetAttribute("ShaftSize", config.ShaftSize)
	map:SetAttribute("ReferenceCFrame", reference.CFrame)
	map:SetAttribute("ReferenceSize", reference.Size)
	map.Parent = workspace

	local report = GeometryValidator.Validate(builder, route, reference, zones)
	report.PartCount = builder.PartCount
	report.Depth = route.Summit
	report.FallenPartsDestroyHeight = workspace.FallenPartsDestroyHeight
	report.Zones = {}
	if topZone then
		table.insert(report.Zones, `{topZone.Model.Name} {topZone.Info.Id}: top pad, pad {topZone.PadSize}`)
	end
	for index, zone in zones do
		local spacing = if index > 1 then zones[index - 1].Elevation - zone.Elevation else nil
		table.insert(report.Zones, `{zone.Model.Name} {zone.Info.Id}: depth {route.Summit - zone.Elevation}{if spacing then ` ({spacing} below the last)` else ""}, pad {zone.PadSize}, gap {zone.Gap}`)
	end
	report.SafeZones = {}
	for _, zone in route.SafeZones do
		table.insert(report.SafeZones, `{zone.Model.Name}: lap {zone.Lap} {zone.Side.Name} corner, depth {route.Summit - zone.Height}`)
	end

	return map, report
end

-- Readable summary of a report.
function MapGenerator.Format(report): string
	local lines = {
		`Parts: {report.PartCount}, depth: {report.Depth}, FallenPartsDestroyHeight: {report.FallenPartsDestroyHeight}`,
	}
	for _, zone in report.Zones do
		table.insert(lines, `  {zone}`)
	end
	for _, zone in report.SafeZones do
		table.insert(lines, `  {zone}`)
	end
	for _, item in report.Checks do
		table.insert(lines, `{item.Passed and "PASS" or "FAIL"}  {item.Name}: {item.Detail}`)
	end
	return table.concat(lines, "\n")
end

return MapGenerator
