local function treeWalker(tree, parent, callback)
	for name, node in pairs(tree) do
		local newParent = callback(name, node, parent)

		if node.Children then
			treeWalker(node.Children, newParent, callback)
		end
	end
end

return treeWalker
