local words = {
	zero = 0,
	one = 1,
	two = 2,
	three = 3,
	four = 4,
	five = 5,
	six = 6,
	seven = 7,
	eight = 8,
	nine = 9,
	ten = 10,
	eleven = 11,
	twelve = 12,
	thirteen = 13,
	fourteen = 14,
	fifteen = 15,
	sixteen = 16,
	seventeen = 17,
	eighteen = 18,
	nineteen = 19,
	twenty = 20,
	thirty = 30,
	forty = 40,
	fifty = 50,
	sixty = 60,
	seventy = 70,
	eighty = 80,
	ninety = 90,
	hundred = 100,
	thousand = 1000,
	million = 1000000,
}

return function(s: string): number?
	s = string.lower(s)
	s = s:gsub("%-", " "):gsub(" and ", " ")

	if words[s] then
		return words[s]
	end

	local total, current = 0, 0
	for token in s:gmatch("%a+") do
		local v = words[token]
		if not v then
			return nil -- unknown word
		end

		if v == 100 then
			current = math.max(1, current) * 100
		elseif v >= 1000 then
			total += math.max(1, current) * v
			current = 0
		else
			current += v
		end
	end
	return total + current
end
