-->
local Module = {}

function Module.snapPositionToGrid(worldPosition, cellSize, grid): Vector3
	local localCFrame = grid:GetPivot():ToObjectSpace(CFrame.new(worldPosition.X, worldPosition.Y, worldPosition.Z))
	local snappedPosition = Vector3.new(
		math.round(localCFrame.Position.X / cellSize) * cellSize,
		math.round(localCFrame.Position.Y / cellSize) * cellSize,
		math.round(localCFrame.Position.Z / cellSize) * cellSize
	)
	return grid:GetPivot():PointToWorldSpace(snappedPosition)
end

function Module.isInGrid(grid: BasePart, worldCFrame: CFrame, objectSize: Vector3)
	local gridCFrane, gridSize = grid:GetPivot(), grid.Size
	local objectCFrame = gridCFrane:ToObjectSpace(worldCFrame)

	local cornerPoints = {}
	for _, x in { -1, 1 } do
		for _, z in { -1, 1 } do
			table.insert(
				cornerPoints,
				objectCFrame:PointToWorldSpace(Vector3.new(x * objectSize.X / 2, 0, z * objectSize / 2))
			)
		end
	end

	for _, corner in cornerPoints do
		if math.abs(corner.X) > gridSize.X / 2 or math.abs(corner.Z) > gridSize.Z / 2 then
			return false
		end
	end
	return true
end

return Module
