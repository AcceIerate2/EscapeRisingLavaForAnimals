-- only for lists!
return function(table1, table2): {}
	local tableToReturn = table.clone(table1)

	local tableStartingLength = #tableToReturn
	for i, v in pairs(table2) do
		tableToReturn[tableStartingLength + i] = v
	end

	return tableToReturn
end
