local T = {
	"K", -- 10^3
	"M", -- 10^6
	"B", -- 10^9
	"T", -- 10^12
	"q", -- 10^15 (quadrillion)
	"Q", -- 10^18 (quintillion)
	"s", -- 10^21 (sextillion)
	"S", -- 10^24 (septillion)
	"O", -- 10^27 (octillion)
	"N", -- 10^30 (nonillion)
	"d", -- 10^33 (decillion)
	"U", -- 10^36 (undecillion)
	"D", -- 10^39 (duodecillion)
	"Td", -- 10^42 (tredecillion)
	"qd", -- 10^45
	"Qd", -- 10^48
	"sd", -- 10^51
	"Sd", -- 10^54
	"Od", -- 10^57
	"Nd", -- 10^60
	"V", -- 10^63 (vigintillion)
	"∞", -- fallback for really huge numbers
}

return function(n)
	if not tonumber(n) then
		return n
	end
	n = tonumber(n)
	if n < 1000 then
		return tostring(math.floor(n))
	end

	local d = math.floor(math.log10(n) / 3) * 3
	local index = math.floor(d / 3)

	-- Cap index to T
	if index > #T then
		index = #T
	end

	local short = n / (10 ^ d)

	-- Round to 3 sig digits total
	local formatted = tonumber(("%.3g"):format(short))

	return tostring(formatted) .. T[index]
end
