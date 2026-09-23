local Module = {}

function Module.SetInstanceOrGroup(_Instance: BasePart | Model | Folder, CollisionName: string)
	if not _Instance or not CollisionName then
		return
	end
	if _Instance:IsA("BasePart") then
		_Instance.CollisionGroup = CollisionName
	end
	local Children = _Instance:GetDescendants() :: { Instance }
	if #Children > 0 then
		for _Index: number, _ChildInstance in pairs(Children) do
			if _ChildInstance:IsA("BasePart") then
				_ChildInstance.CollisionGroup = CollisionName
			end
		end
	end
end

function Module.ToggleCanCollide(_Instance: BasePart | Model | Folder, Toggle: boolean)
	if not _Instance or not Toggle then
		return
	end
	if _Instance:IsA("BasePart") then
		_Instance.CanCollide = Toggle
	end
	local Children = _Instance:GetDescendants() :: { Instance }
	if #Children > 0 then
		for _Index: number, _ChildInstance in pairs(Children) do
			if _ChildInstance:IsA("BasePart") then
				_ChildInstance.CanCollide = Toggle
			end
		end
	end
end

function Module.ToggleCollisionProperties(
	_Instance: BasePart | Model | Folder,
	Props: { [string]: boolean },
	DescToExclude: { Instance }
)
	if not _Instance or not Props then
		return
	end

	local function updateProps(part: BasePart)
		for propName: string, propValue: boolean in pairs(Props) do
			local ok, _ = pcall(function()
				part[propName] = propValue
			end)

			if not ok then
				warn(part, "has no writable property:", propName)
			end
		end
	end

	if _Instance:IsA("BasePart") then
		_Instance.CanCollide = updateProps(_Instance)
	end

	local Children = _Instance:GetDescendants() :: { Instance }
	if #Children > 0 then
		for _Index: number, _ChildInstance in pairs(Children) do
			if _ChildInstance:IsA("BasePart") and table.find(DescToExclude or {}, _ChildInstance) == nil then
				_ChildInstance.CanCollide = updateProps(_ChildInstance)
			end
		end
	end
end

return Module
